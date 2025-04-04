-- Singleton
if ... ~= "__gui-modules__.gui" then
	return require("__gui-modules__.gui")
end
require("__gui-modules__.definitions")
local util = require("util")
---@class ModulesStorage
---@field gui_states {[namespace]:WindowStorage}
storage = {}
---@class ModuleGuiLib : event_handler
modules_gui = {}
---@type {[namespace]:WindowStorage}
local states

local modules = require("__gui-modules__.modules")
local gui_events = require("__gui-modules__.gui_events")
local builder = require("__gui-modules__.gui_builder")
require("util")
---@type table<string, fun(state:modules.WindowState):LuaGuiElement?,any?>
local standard_handlers = {}

---@type table<namespace,true>
local namespaces = {} -- Whether or not the namespace was registered
---@type table<namespace,GuiWindowProcessedDef>
local definitions = {} -- the definitions for each namespace
---@type table<string,namespace>
local shortcut_namespace = {} -- map from shortcut names to namespace
---@type table<namespace, string>
local namespace_shortcut = {} -- map from namespace to shortcut
---@type table<string,namespace>
local custominput_namespace = {} -- map from custominput event names to namespace
---@type table<namespace, string>
local namespace_custominput = {}
local instances = builder.instances
---@type table<namespace,fun(state:modules.WindowState)>
local state_setups = {}

---@type table<namespace,WindowMetadata>?
local namespace_metadata = {} -- Hold onto it locally until we can compare it to the global and store it there

--#region Internal functions

local gui_metatable = {
	__index = modules_gui
}
script.register_metatable("modules_gui_state_metatable", gui_metatable)
gui_metatable = setmetatable({}, gui_metatable)

---Sets up the state using all setup functions
---Given by modules and associated with namespace
---@param state modules.WindowState
local function setup_state(state)
	---MARK: Setup states
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
---@param state modules.WindowState?
---@return modules.WindowState
local function build(player, namespace, state)
	---MARK: Build
	local info = definitions[namespace]
	if not info then
		error({"gui-errors.undefined-namespace-build"}, 2)
	end

	local elems = {}
	local root = builder.buildprocessed(
		player.gui[info.root],
		info.definition,
		elems
	)

	---@type modules.WindowState
	state = state or {}
	state.root = root
	state.elems = elems -- Maybe go through and delete every element that might've not been invalidated?
	state.player = player
	state.pinned = not not state.pinned
	state.shortcut = info.shortcut -- FIXME: Doesn't get shortcuts registered outside window_def
	state.gui = gui_metatable
	state.namespace = namespace


	states[namespace][player.index] = state
	setup_state(state)

	return state
end

---Setsup all necessary values
local function setup()
	---MARK: Setup
	if not namespace_metadata then
		log("Setup called after namespace_metadata has been cleared.")
		return
	end

	for namespace in pairs(namespaces) do
		local new_metadata = namespace_metadata[namespace]

		---@type WindowStorage?
		local namespace_states = states[namespace]

		if not namespace_states then
			-- Wasn't previously setup
			states[namespace] = {}
			for _,player in pairs(game.players) do
				build(player, namespace)
			end

		else
			-- Was previously setup
			local old_metadata = namespace_states[0] or {}--[[@as WindowMetadata]]

			-- destroy and invalidate the elems of all windows
			if old_metadata.version ~= new_metadata.version then
				log(string.format("Migrating %s from version %s to version %s", namespace, old_metadata.version, new_metadata.version))
				for i, state in pairs(namespace_states) do
					if i ~= 0 then
						---@cast state modules.WindowState
						if state.player.valid then
							state.root.destroy()
							state.elems = nil
							build(state.player, namespace, state)
						else
							namespace_states[i] = nil
						end
					end
				end
				namespace_states[0] = new_metadata
			else

				-- Same version. Just let modules setup state
				for index, player in pairs(game.players) do
					local state = namespace_states[index] --[[@as modules.WindowState]]
					if state.root.valid then
						setup_state(state)
					else
						build(player, namespace, state)
					end
				end
			end
		end
	end

	namespace_metadata = nil
end

--#endregion
--#region Standard Event Handlers

--- The function called to close the window
---@param state modules.WindowState
function standard_handlers.close(state)
	---MARK: Close
	if state.pinning then
		state.pinning = nil
		state.player.opened = state.opened
		return
	elseif state.opened then
		if state.player.opened then
			standard_handlers.hide(state)
		else
			state.player.opened = state.root
		end
		return state.opened, defines.events.on_gui_closed
  end
	standard_handlers.hide(state)
end
---The function called by closing the window
---@param state modules.WindowState
function standard_handlers.hide(state)
	---MARK: Hide
	if state.player.opened == state.root then
		state.player.opened = nil -- Clear it from opened if hidden while still opened
		return -- Return because it'll call close, which calls hide again
	end
	state.root.visible = false
	if state.shortcut then -- Update registred shortcut
		state.player.set_shortcut_toggled(state.shortcut, false)
	end
end
---@param state modules.WindowState
function standard_handlers.show(state)
	---MARK: Show
	state.root.visible = true
	if state.shortcut then -- Update registred shortcut
		state.player.set_shortcut_toggled(state.shortcut, true)
	end
	-- Focus something if it should be focused by default
  if not state.pinned then
    state.player.opened = state.root
  end
end
---@param state modules.WindowState
---@return boolean
function standard_handlers.toggle(state)
	---MARK: Toggle
	if state.root.visible then
		standard_handlers.hide(state)
	else
		standard_handlers.show(state)
	end
	return state.root.visible
end
--#endregion
--#region Generic Event Handlers

---Handles the creation of new players
---@param EventData EventData.on_player_created
local function created_player_handler(EventData)
	---MARK: player created
	local player_index = EventData.player_index

	for namespace in pairs(namespaces) do
		-- The state may have already been built by the get_state handler
		-- Let the get state handler built it itself since it already
		-- has the check built-in
---@diagnostic disable-next-line: discard-returns
		modules_gui.get_state(namespace, player_index)
	end
end
---Handles the removal of players
---@param EventData EventData.on_player_removed
local function removed_player_handler(EventData)
	---MARK: player deleted
	for namespace in pairs(namespaces) do
		states[namespace][EventData.player_index] = nil
	end
end
---Opens the element of the player that this event sourced from.
---Will create a new one if one isn't found
---@param EventData EventData.CustomInputEvent|EventData.on_lua_shortcut
local function input_or_shortcut_handler(EventData)
	---MARK: input/shortcut
	---@type namespace
	local namespace
	if EventData.input_name then
		namespace = custominput_namespace[EventData.input_name]
	else
		namespace = shortcut_namespace[EventData.prototype_name]
	end
	if not namespace then return end -- Not one we've been told to handle
	local player = game.get_player(EventData.player_index)
	if not player then return end -- ??

	local state = states[namespace][player.index]
	---@cast state modules.WindowState
	if not state or not state.root.valid then
		state = build(player, namespace, state)
	end

	standard_handlers.toggle(state)
end

---MARK: init
function modules_gui.on_init()
	states = {}
	storage.gui_states = states
	setup()
end
function modules_gui.on_load()
	states = storage.gui_states
end
---Mentions when this library has changed (potentially breaking)
---@param ChangedData ConfigurationChangedData
function modules_gui.on_configuration_changed(ChangedData)
	---MARK: Config changed
	local library_changed = ChangedData.mod_changes["gui-modules"]
	if library_changed and library_changed.old_version ~= nil then
		game.print("Gui Modules has changed version! This library is still in beta and may have had breaking changes")
	end

	setup()
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
---@param children modules.GuiElemDef|modules.GuiElemDef[]
---@param copy? boolean
---@param elems? table<string,LuaGuiElement> The table to accumulate references into. Will default to the elems table in the state
---@return LuaGuiElement
---@return table<string, LuaGuiElement>
function modules_gui.add(namespace, parent, children, copy, elems)
	---MARK: add
	if not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end
	if copy then
		children = table.deepcopy(children) --[[@as modules.GuiElemDef]]
	end
	if not children[1] then
		children = {children}
	end
	if not elems then
		elems = states[namespace][parent.player_index].elems
	end

	---@type LuaGuiElement
	local first
	for _, child in pairs(children) do
		local elem = builder.build(namespace, parent, child, elems)
		if not first then first = elem end
	end
	return first,elems
end

---Returns the WindowState of the given player and namespace.
---Always gurenteed to have the root element valid as it'll
---just rebuild the UI if it's not
---@param namespace namespace
---@param player_index integer
---@return modules.WindowState
---@return boolean did_build Whether or not the state had to be built
---@nodiscard
function modules_gui.get_state(namespace, player_index)
	---MARK: get state
	if not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end

	---@type WindowMetadata|modules.WindowState?
	local state = states[namespace][player_index]
	local built_state = false
	---@cast state modules.WindowState?

	if not state or not state.root or not state.root.valid then
		local player = game.get_player(player_index)
		if not player then
			error{"gui-errors.invalid-player"}
		end
		state = build(player, namespace, state)
		built_state = true
	end

	return state, built_state
end

---Registers a namespace for use
---@param namespace namespace
function modules_gui.new_namespace(namespace)
	---MARK: new namespace
	if namespace:match("/") then
		error{"gui-errors.invalid-namespace", namespace, namespace:match("/")}
	end
	if definitions[namespace] then
		error{"gui-errors.namespace-already-registered", namespace}
	end
	-- This is run before global is available...
	-- global tables are setup in init instead
	-- global[namespace] = global[namespace] or {}
	instances[namespace] = {}
	namespaces[namespace] = true
end
---Registers the shortcut with the window in the namespace.
---@param namespace namespace
---@param shortcut string
---@param skip_check boolean? For internal use
function modules_gui.register_shortcut(namespace, shortcut, skip_check)
	---MARK: register shortcut
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end

	if not skip_check and namespace_shortcut[namespace] then
		error{"gui-errors.shortcut-already-registered", namespace, shortcut}
	end

	shortcut_namespace[shortcut] = namespace
	namespace_shortcut[namespace] = shortcut
end
---Registers the custominput with the window in the namespace.
---@param namespace namespace
---@param custominput string
---@param skip_check boolean? For internal use
function modules_gui.register_custominput(namespace, custominput, skip_check)
	---MARK: register custominput
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace-build"}
	end

	if not skip_check and namespace_custominput[namespace] then
		error{"gui-errors.custominput-already-registered", namespace, custominput}
	end

	modules_gui.events[script.get_event_id(custominput)] = input_or_shortcut_handler
	custominput_namespace[custominput] = namespace
	namespace_custominput[namespace] = custominput
end
---Registers the instance for use in the window's construction
---@param namespace namespace
---@param new_instances table<string,modules.GuiElemDef>
---@param copy boolean?
---@param skip_check boolean? For internal use
function modules_gui.register_instances(namespace, new_instances, copy, skip_check)
	---MARK: register instance/struct
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end
	local registered_instances = instances[namespace]
	for name, instance in pairs(new_instances) do
		if registered_instances[name] then
			error{"gui-errors.instance-already-defined", namespace, name}
		end
		if copy then
			instance = table.deepcopy(instance) --[[@as modules.GuiElemDef]]
		end
		local result = {instance}
		registered_instances[name] = builder.preprocess(namespace, instance)
	end
end
---Registers the WindowState setup function
---@param namespace namespace
---@param state_setup fun(state:modules.WindowState)
---@param skip_check boolean? for internal use
function modules_gui.register_state_setup(namespace, state_setup, skip_check)
	---MARK: register setup func
	if not skip_check and not namespaces[namespace] then
		error{"gui-errors.undefined-namespace"}
	end
	state_setups[namespace] = state_setup
end

---Defines the window of the namespace
---@param namespace namespace
---@param window_def GuiWindowDef
---@param handlers GuiModuleEventHandlers?
---@param instances table<string,modules.GuiElemDef>?
function modules_gui.define_window(namespace, window_def, handlers, instances)
	window_def = util.copy(window_def)
	---MARK: window_def

	if definitions[namespace] then
		error{"gui-errors.namespace-already-defined", namespace}
	end
	window_def.definition = builder.preprocess(namespace, window_def.definition)
	---@cast window_def GuiWindowProcessedDef
	definitions[namespace] = window_def

	-- Either create new namespace, or update missing values
	if not namespaces[namespace] then
		modules_gui.new_namespace(namespace)
	end

	local shortcut = namespace_shortcut[namespace] or window_def.shortcut
	window_def.shortcut = shortcut
	if shortcut and not shortcut_namespace[shortcut] then
		modules_gui.register_shortcut(namespace, shortcut, true)
	end
	local custominput = namespace_custominput[namespace] or window_def.custominput
	window_def.custominput = custominput
	if custominput and not custominput_namespace[custominput] then
		modules_gui.register_custominput(namespace, custominput, true)
	end

	-- Save metadata until it can be put into global
	namespace_metadata[namespace] = {
		version = window_def.version
	}

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
		modules_gui.register_instances(namespace, instances, true, true)
	end
	instances = window_def.instances
	if instances then
		modules_gui.register_instances(namespace, instances, false, true)
	end
end
---@class newWindowParams
---@field window_def GuiWindowDef
---@field handlers GuiModuleEventHandlers?
---@field instances table<string,modules.GuiElemDef>?
---@field shortcut_name string?
---@field custominput_name string?
---@field state_setup fun(state:modules.WindowState)?
---Creates a new namespace with the window definition
---@param params newWindowParams
function modules_gui.new(params)
	---MARK: new()
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