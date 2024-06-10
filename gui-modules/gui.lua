-- Singleton
if ... ~= "__gui-modules__.gui" then
	return require("__gui-modules__.gui")
end

---@type flib_gui
local flib_gui = require("__flib__.gui-lite")
local gui_events = require("__gui-modules__.gui_events")
local every_child = require("__gui-modules__.children-iterator")
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

--- The function called to close the window
---@param self WindowState
function standard_handlers.close(self)
  if self.pinned then
    return
  end
	self.player.opened = nil
end
---The function called by closing the window
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
--#region Generic Event Handlers

---Handles the creation of new players
---@param EventData EventData.on_player_created
function created_player_handler(EventData)
	local player = game.get_player(EventData.player_index)
	if not player then return end -- ??

	for name_space in pairs(definitions) do
		build(player, name_space)
	end
end
---Handles the removal of players
---@param EventData EventData.on_player_removed
function removed_player_handler(EventData)
	for namespace in pairs(definitions) do
		global[namespace][EventData.player_index] = nil
	end
end
---Opens the element of the player that this event sourced from.
---Will create a new one if one isn't found
---@param EventData EventData.CustomInputEvent|EventData.on_lua_shortcut
function input_or_shortcut_handler(EventData)
	local namespace
	if EventData.input_name then
		namespace = custominput_namespace[EventData.input_name]
	else
		namespace = shortcut_namespace[EventData.prototype_name]
	end
	if not namespace then return end -- Not one we've been told to handle
	local player = game.get_player(EventData.player_index)
	if not player then return end -- ??

	local self = global[namespace][player.index]
	if not self or not self.root.valid then
		self = build(player, namespace)
	end

	standard_handlers.toggle(self)
end

local event_lib = gui_events.events
event_lib[defines.events.on_player_created] = created_player_handler
event_lib[defines.events.on_player_removed] = removed_player_handler
event_lib[defines.events.on_lua_shortcut] = input_or_shortcut_handler
--#endregion

---Validates the parameters of the module
---@param module GuiModuleDef
---@param params table
local function validate_module_params(module, params)
	local acceptable_description = module.parameters
	---@type {[string]:ModuleParameterDef}
	local missing = {} -- mark every paramtere as 'missing'
	for key, value in pairs(acceptable_description) do
		missing[key] = value
	end

	-- Validate each present parameter
	for key, value in pairs(params) do
		if key == "type" or key == "module_type" then goto continue end
		missing[key] = nil -- mark as not missing
		local acceptable = acceptable_description[key]

		-- Error on extra parameters
		if not acceptable then
			error({"gui-errors.parameter-extra", module.module_type, key}, 4) -- TODO: Test all error messages
		end

		local is_valid_type = false
		for _, valid_type in pairs(acceptable.type) do
			if type(value) == valid_type then
				is_valid_type = true
				break
			end
		end
		if not is_valid_type then
			error({"gui-errors.parameter-invalid-type", module.module_type, key, type(value)}, 4)
		end

		-- Additional parameter checking possible?
		-- Might grow as the parameters's fields expands
    ::continue::
	end

	-- Error for missing required parameters
	for key, value in pairs(missing) do
		if not value.is_optional then
			error({"gui-errors.parameter-missing", module.module_type, key}, 4)
		end
	end
end

---Expands the module into their elements
---@param namespace namespace
---@param arr GuiElemModuleDef[]
---@param index integer
---@param child GuiElemModuleDef
---@return GuiElemModuleDef
local function expand_module(namespace, arr, index, child)
	if child.type ~= "module" then return child end -- Skip if not module
	local mod_type = child.module_type
	if not mod_type then 
		error({"gui-errors.no-module-name"})
	end

	local module = modules[mod_type]
	validate_module_params(module, child)
	-- Register the module handlers
	gui_events.register(module.handlers, namespace)
	-- replace the module element with the expanded elements
	local new_child = module.build_func(child)
	arr[index] = new_child
	return new_child
end

---Go over every element and expand modules and prepend the namespace to handlers
---@param namespace namespace
---@param definition GuiElemModuleDef[]
local function parse_children(namespace, definition)
	for child_array, index, child in every_child(definition) do
		child = expand_module(namespace, child_array, index, child)
		gui_events.convert_handler_names(namespace, child)
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
-- flib_gui.handle_events() -- flib resolves functions to names and and wraps it in a separate lookup table. It's evil >:(


---Creates a new namespace with the window definition
---@param window_def GuiWindowDef
---@param shortcut_name string?
---@param custominput_name string?
---@return fun(h:GuiModuleEventHandlers):table
function new_namespace(window_def, shortcut_name, custominput_name)
	local namespace = window_def.namespace
	if namespace:match("/") then
		error({"gui-errors.invalid-namespace", namespace, namespace:match("/")}, 2)
	end
	if definitions[namespace] then
		error({"gui-errors.namespace-already-defined", namespace}, 2)
	end
	definitions[namespace] = window_def

	-- TODO: check global to see if there's another version, and purge the UI's if so

	if shortcut_name then
		shortcut_namespace[shortcut_name] = namespace
	end
	if custominput_name then
		custominput_namespace[custominput_name] = namespace
		event_lib[custominput_name] = input_or_shortcut_handler
	end

	---@type GuiModuleEventHandlers
	local handlers = {}
	for key, func in pairs(standard_handlers) do
		handlers[key] = func
	end
	parse_children(namespace, window_def.definition)

	---Adds the handlers to the internal library and registers them with flib
	---@param new_handlers GuiModuleEventHandlers
	local function register_handlers(new_handlers)
		for name, handler in pairs(new_handlers) do
			if handlers[name] then
				log({"gui-warnings.duplicate-handler-name", name})
			end
			handlers[name] = handler
		end
		gui_events.register(handlers, namespace, false)
		global[namespace] = global[namespace] or {}
		global[namespace][0] = window_def.version
	end
	return register_handlers
end

return {
	new = new_namespace,
	events = event_lib,
}