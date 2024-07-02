-- Singleton
if ... ~= "__gui-modules__.gui" then
	return require("__gui-modules__.gui")
end
---@class ModuleGuiLib : event_handler
modules_gui = {}

---@type flib_gui
local flib_gui = require("__flib__.gui-lite")
local gui_events = require("__gui-modules__.gui_events")
local validate_module_params = require("__gui-modules__.module_validation")
require("util")
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
---@type table<namespace,fun(state:WindowState)>
local state_setups = {}

--#region Internal functions

---Resolve the instantiable into a GuiElemModuleDef
---@param namespace namespace
---@param child GuiElemModuleDef
---@param arr GuiElemModuleDef[]
---@param index integer
---@return GuiElemModuleDef
local function resolve_instantiable(namespace, child, arr, index)
	local instance = instances[namespace][child.instantiable_name]
	if not instance then
		error{"gui-errors.invalid-instantiable", namespace, child}
	end
	arr[index] = instance
	return instance
end
---Expands the module into their elements
---@param namespace namespace
---@param child GuiElemModuleDef
---@param arr GuiElemModuleDef[]
---@param index integer
---@return GuiElemModuleDef
local function expand_module(namespace, child, arr, index)
	local mod_type = child.module_type
	if not mod_type then 
		error{"gui-errors.no-module-name"}
	end

	local module = modules[mod_type]
	validate_module_params(module, child)
	-- Register the module handlers
	gui_events.register(module.handlers, namespace)
	-- replace the module element with the expanded elements
	local module = module.build_func(child)
	arr[index] = module
	return module
end
---Go over every element and preprocess it for use in flib_gui
---@param namespace namespace
---@param children GuiElemModuleDef[]
local function parse_children(namespace, children)
	for i = 1, #children do
		-- Cache the child and type
		local child = children[i]
		local type = child.type
		local do_recruse = true

		-- Resolve instantiable if it is one
		if type == "instantiable" then
			do_recruse = false
			child = resolve_instantiable(namespace, child, children, i)
			type = child.type
		end

		-- Expand the module if it is one
		if type == "module" then
			child = expand_module(namespace, child, children, i)
			type = child.type
		end

		if type then
			-- Convert handlers
			gui_events.convert_handler_names(namespace, child)

			-- Recurse into children, if there are any
			local children = child.children
			if do_recruse and children then
				-- Convert single-children into an array
				if children.type then
					children = {children}
					child.children = children
				end
				parse_children(namespace, children)
			end

		-- treat a tab and content like a short children array
		elseif child.tab and child.content then
			parse_children(namespace, {child.tab, child.content})
		end
	end
end

---Sets up the state using all setup functions
---Given by modules and associated with namespace
---@param state any
local function setup_state(state)
	-- Modules
	for _, module in pairs(modules) do
		local init = module.setup_state
		if init then
			init(state)
		end
	end

	-- Namespace
	local init = state_setups[state.namespace]
	if init then
		init(state)
	end
end

---Builds the gui in the namespace for the given player
---@param player LuaPlayer
---@param namespace string
---@return WindowState
local function build(player, namespace)
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
		shortcut = info.shortcut,
		gui = modules_gui,
		namespace = namespace
	}
	setup_state(self)
	global[namespace][player.index] = self

	return self
end

--#endregion
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
local function created_player_handler(EventData)
	local player = game.get_player(EventData.player_index)
	if not player then return end -- ??

	for name_space in pairs(definitions) do
		build(player, name_space)
	end
end
---Handles the removal of players
---@param EventData EventData.on_player_removed
local function removed_player_handler(EventData)
	for namespace in pairs(definitions) do
		global[namespace][EventData.player_index] = nil
	end
end
---Opens the element of the player that this event sourced from.
---Will create a new one if one isn't found
---@param EventData EventData.CustomInputEvent|EventData.on_lua_shortcut
local function input_or_shortcut_handler(EventData)
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
---Mentions when this library has changed (potentially breaking)
---@param ChangedData ConfigurationChangedData
function modules_gui.on_configuration_changed(ChangedData)
	local library_changed = ChangedData.mod_changes["gui-modules"]
	if library_changed and library_changed.old_version ~= nil then
		game.print("Gui Modules has changed version! This library is still in beta and may have had breaking changes")
	end

	for _, namespace in pairs(namespaces) do
		---@type table<integer,WindowState>
		local namespace_states = global[namespace]

		for index in game.players do
			local state = namespace_states[index]
			setup_state(state)
		end
	end
end

modules_gui.events = gui_events.events
modules_gui.events[defines.events.on_player_created] = created_player_handler
modules_gui.events[defines.events.on_player_removed] = removed_player_handler
modules_gui.events[defines.events.on_lua_shortcut] = input_or_shortcut_handler
--#endregion


---Parses and creates the entity.
---
---This loops over the table 2-3 times to 
---1. deepcopy (optional)
---2. parse and convert for flib use
---3. Actually build with flib
---
---Instances are pre-parsed, so the better option would be
---to register all instances at the start so you only have to build it
---@param namespace namespace
---@param parent LuaGuiElement
---@param new_child GuiElemModuleDef
---@param do_not_copy boolean?
---@return LuaGuiElement
---@return table<string, LuaGuiElement>
function modules_gui.add(namespace, parent, new_child, do_not_copy)
	if not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end
	if not do_not_copy then
		new_child = table.deepcopy(new_child) --[[@as GuiElemModuleDef]]
	end
	local result = {new_child}
	parse_children(namespace, result)
	local elems,new_elem = flib_gui.add(parent, result[1], global[namespace][parent.player_index].elems)
	return new_elem,elems
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
---@param namespace namespace
---@param shortcut string
---@param skip_check boolean? For internal use
function modules_gui.register_shortcut(namespace, shortcut, skip_check)
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end
	shortcut_namespace[shortcut] = namespace
end
---Registers the custominput with the window in the namespace.
---@param namespace namespace
---@param custominput string
---@param skip_check boolean? For internal use
function modules_gui.register_custominput(namespace, custominput, skip_check)
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace-build"}
	end

	modules_gui.events[custominput] = input_or_shortcut_handler
	custominput_namespace[custominput] = namespace
end
---Registers the instance for use in the window's construction
---@param namespace namespace
---@param new_instances table<string,GuiElemModuleDef>
---@param do_not_copy boolean?
---@param skip_check boolean? For internal use
function modules_gui.register_instances(namespace, new_instances, do_not_copy, skip_check)
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end
	local registered_instances = instances[namespace]
	for name, instance in pairs(new_instances) do
		if registered_instances[name] then
			error{"gui-errors.instance-already-defined", namespace, name}
		end
		if not do_not_copy then
			instance = table.deepcopy(instance) --[[@as GuiElemModuleDef]]
		end
		local result = {instance}
		parse_children(namespace, result)
		registered_instances[name] = result[1]
	end
end
---Registers the WindowState setup function
---@param namespace namespace
---@param state_setup fun(state:WindowState)
---@param skip_check boolean? for internal use
function modules_gui.register_state_setup(namespace, state_setup, skip_check)
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end
	state_setups[namespace] = state_setup
end

---Defines the window of the namespace
---@param namespace namespace
---@param window_def GuiWindowDef
---@param handlers GuiModuleEventHandlers?
---@param instances table<string,GuiElemModuleDef>?
function modules_gui.define_window(namespace, window_def, handlers, instances)
	-- Either create new namespace, or update missing values
	if not namespaces[namespace] then
		modules_gui.new_namespace(namespace)
	end

	local shortcut = window_def.shortcut
	if shortcut and not shortcut_namespace[shortcut] then
		modules_gui.register_shortcut(namespace, shortcut, true)
	end
	local custominput = window_def.custominput
	if custominput and not custominput_namespace[custominput] then
		modules_gui.register_custominput(namespace, custominput, true)
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

	if instances then
		modules_gui.register_instances(namespace, instances, false, true)
	end
	instances = window_def.instances
	if instances then
		modules_gui.register_instances(namespace, instances, true, true)
	end

	local results = {window_def.definition}
	parse_children(namespace, results)
	window_def.definition = results[1]
end
---@class newWindowParams
---@field window_def GuiWindowDef
---@field handlers GuiModuleEventHandlers?
---@field instances table<string,GuiElemModuleDef>?
---@field shortcut_name string?
---@field custominput_name string?
---@field state_setup fun(state:WindowState)?
---Creates a new namespace with the window definition
---@param params newWindowParams
function modules_gui.new(params)
	local namespace = params.window_def.namespace
	modules_gui.new_namespace(namespace)
	if params.shortcut_name then
		modules_gui.register_shortcut(namespace, params.shortcut_name, true)
	end
	if params.custominput_name then
		modules_gui.register_custominput(namespace, params.custominput_name, true)
	end
	if params.state_setup then
		modules_gui.register_state_setup(namespace, params.state_setup, true)
	end
	modules_gui.define_window(namespace, params.window_def, params.handlers, params.instances)
end

return modules_gui