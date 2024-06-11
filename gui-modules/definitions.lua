---@meta

---@alias namespace string

---@class GuiElemModuleDef : GuiElemDef
---@field type GuiElementType|"module"
---@field children GuiElemModuleDef[]?
---@field module_type string? The name of the module
---@field handler GuiModuleEventHandlerNames?

---@class GuiWindowDef
---@field namespace string the namespace the global table is put into
---@field version integer the version of the UI. Will automatically recreate the UI if the stored version is different than the given one
---@field definition GuiElemModuleDef[] the elements/modules used to create the window
---@field root "top"|"left"|"center"|"goal"|"screen"
---@field custominput string?
---@field shortcut string?

---@alias GuiModuleEventHandler fun(self:WindowState,elem:LuaGuiElement,event:GuiEventData,namespace:string):LuaGuiElement?,any?
---@alias GuiModuleEventHandlers table<any, GuiModuleEventHandler>
---@alias GuiModuleEventHandlersMap table<string, GuiModuleEventHandler>
---@alias GuiModuleEventHandlerNames string|table<defines.events,string>

---@class ModuleDef : GuiElemModuleDef
---@class ModuleParameterDef
---@field is_optional boolean Whether or not this parameter is required
---@field type type[] The possible types of this parameter
---@field enum string[]? The possible values for a string
---@alias ModuleParameterDict {[string]:ModuleParameterDef}

---@class GuiModuleDef
---@field module_type string the name of the module
---@field build_func fun(parameters:table):GuiElemModuleDef the function to return a GuiElemDef out of the passed definition
---@field parameters ModuleParameterDict a table defining the possible parameters of the module
---@field handlers GuiModuleEventHandlers the handlers the module uses.

---@class WindowState
---@field root LuaGuiElement the root element
---@field elems table<string,LuaGuiElement> the named elements
---@field player LuaPlayer the owner of the window
---@field pinned boolean Whether or not the window has been pinned
---@field shortcut string? The registered shortcut for the window