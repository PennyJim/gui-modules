---@type flib_gui
local flib_gui = require("__flib__.gui-lite")
local every_child = require("__gui-modules__.children-iterator")
local main = {}
local standard_handlers = {}

---@type {[string]:GuiModuleDef}
local modules = {}
do -- Grab the modules from startup settings
	local prefix = "gui_module_add_"
	for name, setting in pairs(settings.startup) do
		if name:find(prefix) then
			---@type GuiModuleDef
			local module = require(setting.value --[[@as string]])
			modules[module.module_type] = module
		end
	end
end

---@type {[namespace]:GuiWindowDef}
local definitions = {} -- the definitions for each namespace
---@type {[namespace]:GuiModuleEventHandlers}
local namespace_handlers = {} -- The dictionary of handlers for each namespace
---@type {[string]:namespace}
local shortcut_namespace = {} -- map from shortcut names to namespace 
---@type {[string]:namespace}
local custominput_namespace = {} -- map from custominput event names to namespace

--#region Standard Event Handlers

---@param self WindowState
function standard_handlers.hide(self)
  self.root.visible = false
end
---@param self WindowState
function standard_handlers.show(self)
	self.root.visible = true
	-- Focus something if it should be focused by default
  if not self.pinned then
    self.player.opened = self.root
  end
end
---@param self WindowState
---@return boolean
function standard_handlers.toggle(self)
	if self.root.visible then
		standard_handlers.hide(self)
	else
		standard_handlers.show(self)
	end
	return self.root.visible
end
--#endregion

---Validates the parameters of the module
---@param module GuiModuleDef
---@param params table
local function validate_module_params(module, params)
	local acceptable_description = module.parameters
	local missing = table.deepcopy(module.parameters)

	-- Validate each present parameter
	for key, value in pairs(params) do
		if key == "type" or key == "module_type" then goto continue end
		missing[key] = nil -- mark as not missing
		local acceptable = acceptable_description[key]

		-- Error on extra parameters
		if not acceptable then
			error({"gui-errors.parameter-extra", module.module_type, key}, 3)
		end

		local is_valid_type = false
		for _, valid_type in pairs(acceptable.type) do
			if type(value) == valid_type then
				is_valid_type = true
				break
			end
		end
		if not is_valid_type then
			error({"gui-errors.parameter-invalid-type", module.module_type, key, type(value)}, 3)
		end

		-- Additional parameter checking possible?
		-- Might grow as the parameters's fields expands
    ::continue::
	end

	-- Error for missing required parameters
	for key, value in pairs(missing) do
		if not value.is_optional then
			error({"gui-errors.parameter-missing", module.module_type, key}, 3)
		end
	end
end

---Go over every element,
---Convert modules into their elements, and
---Resolve handler names into the handlers
---@param definition GuiElemModuleDef[]
function expand_modules(definition)
	for child_array, index, child in every_child(definition) do
		if child.type == "module" then
			if not child.module_type then
				error({"gui-errors.no-module-name"})
			end
			---@type GuiModuleDef
			local module = modules[child.module_type]
			validate_module_params(module, child)
			child = module.build_func(child)
		end
	end
end

---Builds the gui in the namespace for the given player
---@param player LuaPlayer
---@param namespace string
---@return WindowState
function build(player, namespace)
	local info = definitions[namespace]
	if not info then
		error({"gui-errors.undefined-namespace"}, 2)
	end

	local elems, root = flib_gui.add(
		player.gui[info.root],
		info.definition
	)

	---@type WindowState
	local self = {
		root = root,
		elems = elems,
		player = player,
		pinned = false
	}
	global[namespace][player.index] = self
	-- TODO: initialize windowstate values defined in `info`

	return self
end

---Creates the wrapper for the namespace
---@param namespace string
---@return fun(e,h:fun(self,s,e))
local function event_wrapper(namespace)
	return function (e, handler)
		local self = global[namespace][e.player_index]
		if not self then return end

		if self.root.valid then
			handler(self, namespace, e)
		else
			-- Delete the entry of an invalid gui
			global[namespace][e.player_index] = nil
		end
	end
end
flib_gui.handle_events()


---Creates a new namespace with the window definition
---@param window_def GuiWindowDef
---@return fun()
function new_namespace(window_def)
	local namespace = window_def.namespace
	definitions[namespace] = window_def

	global[namespace][0] = window_def.version
	expand_modules(window_def.definition)

	---@type GuiModuleEventHandlers
	local handlers = {
		["hide"] = standard_handlers.hide,
		["show"] = standard_handlers.show,
		["toggle"] = standard_handlers.toggle,
	}
	namespace_handlers[namespace] = handlers

	---Adds the handlers to the internal library and registers them with flib
	---@param new_handlers GuiModuleEventHandlers
	local function register_handlers(new_handlers, shortcut_name, custominput_name)
		for name, handler in pairs(new_handlers) do
			if handlers[name] then
				log({"gui-errors.duplicate-handler-name", name})
			end
			handlers[name] = handler
		end
		-- FIXME: Might require us to prepend the names with the namespace to avoid collisions. Check that before releasing
		flib_gui.add_handlers(handlers, event_wrapper(namespace))
		global[namespace].has_registered = true

		if shortcut_name then
			shortcut_namespace[shortcut_name] = namespace
		end
		if custominput_name then
			custominput_namespace[custominput_name] = namespace
		end

	end
	return register_handlers
end

---Initialization
function main.init()
	for name_space in pairs(definitions) do
		global[name_space] = global[name_space] or {}
	end
end
---Handles the events of new players
---@param EventData EventData.on_player_created
function main.created_player_handler(EventData)
	local player = game.get_player(EventData.player_index)
	if not player then return end -- ??

	for name_space in pairs(definitions) do
		build(player, name_space)
	end
end
---Opens the element of the player that this event sourced from.
---Will create a new one if one isn't found
---@param EventData EventData.CustomInputEvent
---@return boolean? -- The state of the window, if player existed
---@overload fun(EventData:EventData.on_lua_shortcut,player:LuaPlayer,namespace:namespace):boolean
function main.custominput_handler(EventData, player, namespace)
	namespace = namespace or custominput_namespace[EventData.name]
	if not namespace then return end -- Not one we've been told to handle
	player = player or game.get_player(EventData.player_index)
	if not player then return end -- ??

	local self = global[namespace][player.index]
	if not self or not self.root.valid then
		self = build(player, namespace)
	end

	return standard_handlers.toggle(self)
end
---Handles the custom input events
---@param EventData EventData.on_lua_shortcut
function main.shortcut_handler(EventData)
	local namespace = shortcut_namespace[EventData.prototype_name]
	if not namespace then return end -- Not one we've been told to handle
	local player = game.get_player(EventData.player_index)
	if not player then return end -- ??

	local new_state = main.custominput_handler(EventData, player, namespace)
	player.set_shortcut_toggled(EventData.prototype_name, new_state)
end
-- TODO: add a configuration changed handler that tracks what version of of UI it is
-- If the version is different, just kill and rebuild the menus

return main