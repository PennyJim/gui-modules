local module = {module_type = "my_module", handlers = {}}

---@class WindowState.my_module : WindowState
-- Where custom fields would go

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
}

---@class myModuleParams : ModuleDef
-- where LuaLS parameter definitons go
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	-- = {is_optional = false, type = {"string","table"}},
}

---Creates the frame for a window with an exit button
---@param params myModuleParams
---@return GuiElemDef
function module.build_func(params)
	return {}
end

-- How to define handlers
-- ---@param self WindowState.my_module
-- module.handlers[handler_names.my_handler] = function (self)
-- 	-- Do stuff
-- end

return module --[[@as GuiModuleDef]]