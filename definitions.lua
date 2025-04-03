---@meta

---@alias namespace string

---@class Storage
---@field gui_states {[string]:WindowStorage}

---@class modules.GuiElemDef.base
---The name under which this element will be stored in the reference table, or false if not to store it at all.
---@field ref? string|false
---The element arguments.
---@field args? LuaGuiElement.add_param
---Modifications to make to the element itself.
---@field elem_mods? LuaGuiElement
---Modifications to make to the element's style.
---@field style_mods? LuaStyle
---Set the element's drag target to the one that matches the string
---@field drag_target? string
---The handler(s) for the GUI events regarding this element.
---@field handler? GuiModuleEventHandlerNames
---Children to add to this element.
---@field children? modules.GuiElemDef[]

---@class modules.GuiElemDef.tab
---To add a tab, specify `tab` and `content` and leave all other fields unset.
---@field tab? modules.GuiElemDef
---To add a tab, specify `tab` and `content` and leave all other fields unset.
---@field content? modules.GuiElemDef

---@class modules.GuiSimpleElemDef.base : modules.GuiElemDef.base
---@field children? modules.GuiSimpleElemDef[]
---@class modules.GuiSimpleElemDef.tab : modules.GuiElemDef.tab
---@field tab? modules.GuiSimpleElemDef
---@field content? modules.GuiSimpleElemDef
---@alias modules.GuiSimpleElemDef modules.GuiSimpleElemDef.base|modules.GuiSimpleElemDef.tab

---@class modules.GuiTaggedElemDef.base : modules.GuiSimpleElemDef.base
---@field handler nil Should already be in tags
---@field children? modules.GuiTaggedElemDef[]
---@class modules.GuiTaggedElemDef.tab : modules.GuiSimpleElemDef.tab
---@field tab? modules.GuiTaggedElemDef
---@field content? modules.GuiTaggedElemDef
---@alias modules.GuiTaggedElemDef modules.GuiTaggedElemDef.base|modules.GuiTaggedElemDef.tab

---@class modules.GuiElemDef.instance
---@field instantiable_name string

---@alias (partial) modules.ModuleParams
---| modules.myModuleElem
---@alias modules.GuiElemDef
---| modules.GuiElemDef.base
---| modules.GuiElemDef.tab
---| modules.GuiElemDef.instance
---| modules.ModuleElems Each module should add themselves to this alias

---@class GuiWindowDef
---@field namespace string the namespace the global table is put into
---@field version integer the version of the UI. Will automatically recreate the UI if the stored version is different than the given one
---@field instances table<string,modules.GuiElemDef>?
---@field definition modules.GuiElemDef the element/module used to create the window
---@field root "top"|"left"|"center"|"goal"|"screen"
---@field custominput string?
---@field shortcut string?
---@class GuiWindowProcessedDef : GuiWindowDef
---@field definition modules.GuiTaggedElemDef

---@alias GuiModuleEventHandler fun(state:modules.WindowState,elem:LuaGuiElement,event:flib.GuiEventData):LuaGuiElement?,any?
---@alias GuiModuleEventHandlers table<any, GuiModuleEventHandler>
---@alias GuiModuleEventHandlersMap table<string, GuiModuleEventHandler>
---@alias GuiModuleEventHandlerNames string|table<string,string>

---@class modules.ModuleParameterDef
---@field is_optional boolean Whether or not this parameter is required
---@field type (type|LuaObject.object_name)[] The possible types of this parameter
---@field enum string[]? The possible values for a string
---@field default any The value that nil is treated as
---@alias ModuleParameterDict table<string,modules.ModuleParameterDef>

---The possible names of modules
---@alias (partial) modules.types
---| "my_module" An example

---@class modules.GuiModuleDef
---@field module_type modules.types the name of the module
---@field setup_state fun(state:modules.WindowState)? The function to setup state values used in this module
---@field build_func fun(parameters:table):modules.GuiSimpleElemDef the function to return a GuiElemDef out of the passed definition
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

---@class WindowStorage : {[integer]: modules.WindowState}
---@field [0] WindowMetadata