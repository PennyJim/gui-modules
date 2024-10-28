---@meta

---@alias namespace string

---@class Global
---@field gui_states {[string]:WindowGlobal}

---@class modules.GuiElemModuleDef : flib.GuiElemDef
---@field type GuiElementType|"module"|"instantiable"
---@field children modules.GuiElemModuleDef[]|modules.GuiElemModuleDef?
---@field tab modules.GuiElemModuleDef?
---@field content modules.GuiElemModuleDef?
---@field module_type string? The name of the module
---@field instantiable_name string? The name of the instantiable
---@field handler GuiModuleEventHandlerNames?

---@class GuiWindowDef
---@field namespace string the namespace the global table is put into
---@field version integer the version of the UI. Will automatically recreate the UI if the stored version is different than the given one
---@field instances table<string,modules.GuiElemModuleDef>?
---@field definition modules.GuiElemModuleDef the element/module used to create the window
---@field root "top"|"left"|"center"|"goal"|"screen"
---@field custominput string?
---@field shortcut string?

---@alias GuiModuleEventHandler fun(state:modules.WindowState,elem:LuaGuiElement,event:flib.GuiEventData):LuaGuiElement?,any?
---@alias GuiModuleEventHandlers table<any, GuiModuleEventHandler>
---@alias GuiModuleEventHandlersMap table<string, GuiModuleEventHandler>
---@alias GuiModuleEventHandlerNames string|table<string,string>

---@class modules.ModuleDef : modules.GuiElemModuleDef
---@class modules.ModuleParameterDef
---@field is_optional boolean Whether or not this parameter is required
---@field type type[] The possible types of this parameter
---@field enum string[]? The possible values for a string
---@field default any The value that nil is treated as
---@alias ModuleParameterDict table<string,modules.ModuleParameterDef>

---@class modules.GuiModuleDef
---@field module_type string the name of the module
---@field setup_state fun(state:modules.WindowState)? The function to setup state values used in this module
---@field build_func fun(parameters:table):modules.GuiElemModuleDef the function to return a GuiElemDef out of the passed definition
---@field parameters ModuleParameterDict a table defining the possible parameters of the module
---@field handlers GuiModuleEventHandlers the handlers the module uses.

---@class modules.WindowState
---@field root LuaGuiElement the root element
---@field namespace namespace the namepsace of this state
---@field elems table<string,LuaGuiElement> the named elements
---@field player LuaPlayer the owner of the window
---@field pinned boolean Whether or not the window has been pinned
---@field pinning boolean? Whether or not to pass the close event to an opened subelement
---@field shortcut string? The registered shortcut for the window
---@field opened LuaGuiElement? Should be set when subelements are opened. So the main element can close them instead
---@field gui ModuleGuiLib A reference to the library table meant to be used in creation of new elements

---@class WindowMetadata
---@field version any The version of the window definition. Will reconstruct the window if this differs

---@class WindowGlobal : {[integer]: modules.WindowState}
---@field [0] WindowMetadata