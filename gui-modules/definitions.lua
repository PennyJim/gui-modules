---@meta

---@class GuiElemModuleDef : GuiElemDef (might be element)
-- if type == "module" then module_type must be set

---@class GuiWindowDef
---@field namespace string the namespace the global table is put into
---@field version integer the version of the UI. Will automatically recreate the UI if the stored version is different than the given one
---@field definition GuiElemModuleDef[] the elements/modules used to create the window

---@class GuiModuleDef
---@field module_type string the name of the module
---@field build_func fun(parameters:table):GuiElemModuleDef the function to return a GuiElemDef out of the passed definition
---@field parameters table a table defining the possible parameters of the module
---@field handlers {[string]:fun(self:WindowState,event:EventData)} the handlers the module uses.