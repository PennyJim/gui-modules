local module = {module_type = "my_module", handlers = {} --[[@as GuiModuleEventHandlers]]}

---@class WindowState.my_module : WindowState
-- Where custom fields would go

---WindowState.my_module
---@param state table
module.setup_state = function(state)
	-- Setup your own fields here or restore
	-- elements after the window was recreated
end

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
	my_handler = "my_module.my_handler" -- Standardly prepended with module name to avoid naming collisions
}

---@class myModuleParams : ModuleDef
---@field module_type "my_module"
-- where LuaLS parameter definitons go
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	my_parameter = {is_optional = false, type = {"string","table"}},
	my_optional_parameter = {
		is_optional = true, type = {"string"},
		enum = {"one value","other value"},
		default = "one value",
	}
}

---Creates the frame for a window with an exit button
---@param params myModuleParams
---@return GuiElemDef
function module.build_func(params)
	return {}
end

-- How to define handlers
---@param state WindowState.my_module
module.handlers[handler_names.my_handler] = function (state, elem, OriginalEvent)
	-- Do stuff
end

return module --[[@as GuiModuleDef]]