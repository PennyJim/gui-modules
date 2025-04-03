---@diagnostic disable: assign-type-mismatch
---@type modules.GuiModuleDef
---@diagnostic disable-next-line: missing-fields
local module = {
	module_type = "module_validation_test",
	handlers = {}
}

---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	my_parameter = {is_optional = false, type = {"table"}},
	my_enum_parameter = {
		is_optional = false, type = {"string"},
		enum = {"one value","other value"},
	},
	my_optional_parameter = {
		is_optional = true, type = {"string"},
		default = "one value",
	},
	my_both_parameter = {
		is_optional = true, type = {"string"},
		enum = {"one value","other value"},
		default = "one value",
	}
}

---@diagnostic disable-next-line: missing-return
function module.build_func() end

-- Strictly speaking, this does not test every case so
-- bugs may sneak through, but this should catch most

-- module.module_type = {} -- Not a string
-- module.module_type = "window_frame" -- Pre-existing module (log)
-- module.build_func = "not-a-function"
-- module.handlers = "not-a-table"
-- module.parameters = "not-a-table"

-- module.handlers[{}] = "This is really stupid, but I just *know* someone is going to do it. I __refuse__ to let that happen"
-- module.handlers.bad_handler = "not-a-function"

-- module.parameters[1] = "not-string-key"
-- module.parameters.my_parameter = "not-a-table"
-- module.parameters.my_parameter.is_optional = "not-a-boolean"
-- module.parameters.my_parameter.type = "not-a-table"
-- module.parameters.my_parameter.type[1] = "not-a-type"

-- module.parameters.my_parameter.enum = {} -- Isn't enumable
-- module.parameters.my_enum_parameter.enum = "not-a-table"
-- module.parameters.my_enum_parameter.enum[1] = 1 -- Not a string

-- module.parameters.my_parameter.default = "extra-default"
-- module.parameters.my_optional_parameter.default = {} -- not in type table
-- module.parameters.my_both_parameter.default = "not-in-enum"

return module --[[@as modules.GuiModuleDef]]