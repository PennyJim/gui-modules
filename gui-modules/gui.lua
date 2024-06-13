-- Singleton
if ... ~= "__gui-modules__.gui" then
	return require("__gui-modules__.gui")
end
modules_gui = {}

---@type flib_gui
local flib_gui = require("__flib__.gui-lite")
local gui_events = require("__gui-modules__.gui_events")
local validate_module_params = require("__gui-modules__.module_validation")
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

---@type table<namespace,true>
local namespaces = {} -- Whether or not the namespace was registered
---@type table<namespace,GuiWindowDef>
local definitions = {} -- the definitions for each namespace
---@type table<string,namespace>
local shortcut_namespace = {} -- map from shortcut names to namespace 
---@type table<string,namespace>
local custominput_namespace = {} -- map from custominput event names to namespace
---@type table<namespace,table<string,GuiElemModuleDef>>
local instances = {}

--#region Standard Event Handlers

--- The function called to close the window
---@param self WindowState
function standard_handlers.close(self)
	if self.pinning then
		self.pinning = nil
		self.player.opened = self.opened
		return
	elseif self.opened then
		if self.player.opened then
			standard_handlers.hide(self)
		else
			self.player.opened = self.root
		end
		return self.opened, defines.events.on_gui_closed
  end
	standard_handlers.hide(self)
end
---The function called by closing the window
---@param self WindowState
function standard_handlers.hide(self)
	if self.player.opened == self.root then
		self.player.opened = nil -- Clear it from opened if hidden while still opened
		return -- Return because it'll call close, which calls hide again
	end
	self.root.visible = false
	if self.shortcut then -- Update registred shortcut
		self.player.set_shortcut_toggled(self.shortcut, false)
	end
end
---@param self WindowState
function standard_handlers.show(self)
	self.root.visible = true
	if self.shortcut then -- Update registred shortcut
		self.player.set_shortcut_toggled(self.shortcut, true)
	end
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

modules_gui.events = gui_events.events
modules_gui.events[defines.events.on_player_created] = created_player_handler
modules_gui.events[defines.events.on_player_removed] = removed_player_handler
modules_gui.events[defines.events.on_lua_shortcut] = input_or_shortcut_handler
--#endregion

---Resolve the instantiable into a GuiElemModuleDef
---@param namespace namespace
---@param arr GuiElemModuleDef[]
---@param index integer
---@param child GuiElemModuleDef
---@return GuiElemModuleDef
local function resolve_instantiable(namespace, arr, index, child)
	local instance = instances[namespace][child.instantiable_name]
	if not instance then
		error{"gui-errors.invalid-instantiable", namespace, child}
	end
	arr[index] = instance
	return instance
end
---Expands the module into their elements
---@param namespace namespace
---@param arr GuiElemModuleDef[]
---@param index integer
---@param child GuiElemModuleDef
---@return GuiElemModuleDef
local function expand_module(namespace, arr, index, child)
	local mod_type = child.module_type
	if not mod_type then 
		error{"gui-errors.no-module-name"}
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
---Go over every element and preprocess it for use in flib_gui
---@param namespace namespace
---@param children GuiElemModuleDef|GuiElemModuleDef[]
local function parse_children(namespace, children)
	-- Convert single-children into an array
	if children.type then
		children = {children}
	end

	for i = 1, #children do
		-- Cache the child and type
		local child = children[i]
		local type = child.type

		-- Resolve instantiable if it is one
		if type == "instantiable" then
			child = resolve_instantiable(namespace, children, i, child)
			type = child.type
		end

		-- Expand the module if it is one
		if type == "module" then
			child = expand_module(namespace, children, i, child)
			type = child.type
		end

		if type then
			-- Convert handlers
			gui_events.convert_handler_names(namespace, child)

			-- Recurse into children, if there are any
			local children = child.children
			if children then
				parse_children(namespace, children)
			end

		-- treat a tab and content like a short children array
		elseif child.tab and child.content then
			parse_children(namespace, {child.tab, child.content})
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
		error({"gui-errors.undefined-namespace-build"}, 2)
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
		pinned = false,
		shortcut = info.shortcut
	}
	global[namespace][player.index] = self
	-- TODO: initialize windowstate values defined in `info`

	return self
end

---Registers a namespace for use
---@param namespace namespace
function modules_gui.new_namespace(namespace)
	if namespace:match("/") then
		error{"gui-errors.invalid-namespace", namespace, namespace:match("/")}
	end
	if definitions[namespace] then
		error{"gui-errors.namespace-already-registered", namespace}
	end
	global[namespace] = global[namespace] or {}
	instances[namespace] = {}
	namespaces[namespace] = true
end
---Registers the shortcut with the window in the namespace.
---Passing nil will unregister it
---@param namespace namespace
---@param shortcut string?
function modules_gui.register_shortcut(namespace, shortcut, skip_check)
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end
	shortcut_namespace[namespace] = shortcut
end
---Registers the custominput with the window in the namespace.
---Passing nil will unregister it
---@param namespace namespace
---@param custominput string?
---@param skip_check boolean?
function modules_gui.register_custominput(namespace, custominput, skip_check)
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace-build"}
	end
	custominput_namespace[namespace] = custominput
	if custominput then
		modules_gui.events[custominput] = input_or_shortcut_handler
		custominput_namespace[namespace] = custominput
	end
end

---Defines the window of the namespace
---@param namespace namespace
---@param window_def GuiWindowDef
---@param handlers GuiModuleEventHandlers?
function modules_gui.define_window(namespace, window_def, handlers)
	-- Either create new namespace, or update missing values
	if not namespaces[namespace] then
		modules_gui.new_namespace(namespace)
		modules_gui.register_shortcut(namespace, window_def.shortcut)
		modules_gui.register_custominput(namespace, window_def.custominput)
	else
		if not shortcut_namespace[namespace] then
			modules_gui.register_shortcut(namespace, window_def.shortcut)
		end
		if not custominput_namespace[namespace] then
			modules_gui.register_custominput(namespace, window_def.custominput)
		end
	end
	if definitions[namespace] then
		error{"gui-errors.namespace-already-defined", namespace}
	end
	definitions[namespace] = window_def

	-- Handle version change
	---@type WindowState[]
	local namespace_states = global[namespace]
	if namespace_states[0] ~= window_def.version then
		log(string.format("Migrating %s from version %s to version %s", namespace, namespace_states[0], window_def.version))
		for i, self in pairs(namespace_states) do
			self.root.destroy()
			namespace_states[i] = nil
		end
	end
	namespace_states[0] = window_def.version

	handlers = handlers or {}
	for name, func in pairs(standard_handlers) do
		if handlers[name] then
			log({"gui-warnings.duplicate-handler-name", name})
		else
			handlers[name] = func
		end
	end
	gui_events.register(handlers, namespace, false)
	parse_children(namespace, window_def.definition)
end
---Creates a new namespace with the window definition
---@param window_def GuiWindowDef
---@param handlers GuiModuleEventHandlers?
---@param shortcut_name string?
---@param custominput_name string?
function modules_gui.new(window_def, handlers, shortcut_name, custominput_name)
	local namespace = window_def.namespace
	modules_gui.new_namespace(namespace, 2)
	modules_gui.register_shortcut(namespace, shortcut_name, 2)
	modules_gui.register_custominput(namespace, custominput_name, 2)
	modules_gui.define_window(namespace, window_def, handlers, 2)
end

return modules_gui