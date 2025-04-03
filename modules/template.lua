---@type modules.GuiModuleDef
---@diagnostic disable-next-line: missing-fields
local module = {
	module_type = "my_module",
	handlers = {}
}

---@class WindowState.my_module : modules.WindowState
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

---@alias (partial) modules.types
---| "my_module"
---@alias (partial) modules.ModuleElems
---| modules.myModuleElem
---@class modules.myModuleElem
---@field module_type "my_module"
---@field args modules.myModuleArgs

---@class modules.myModuleArgs
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
---@param params modules.myModuleArgs
function module.build_func(params)
	return {

	}--[[@as modules.GuiSimpleElemDef]] -- This helps luals guide you
end

-- How to define handlers
---@param state WindowState.my_module
module.handlers[handler_names.my_handler] = function (state, elem, OriginalEvent)
	-- Do stuff
end

return module