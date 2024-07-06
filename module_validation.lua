---@param value ModuleParameterDef
---@param acceptable_type type[]
---@param module_type string
local function type_validation(key, value, acceptable_type, module_type)
	local is_valid_type = false
	for _, valid_type in pairs(acceptable_type) do
		if type(value) == valid_type then
			is_valid_type = true
			break
		end
	end

	if not is_valid_type then
		error({"module-errors.parameter-invalid-type", module_type, key, type(value)}, 5)
	end
end

---@param value ModuleParameterDef
---@param acceptable_values any[]
---@param module_type string
local function enum_validation(key, value, acceptable_values, module_type)
	if type(value) ~= "string" then return end
	if not acceptable_values then return end

	local matches = false
	for _, valid_value in pairs(acceptable_values) do
		if value == valid_value then
			matches = true
			break
		end
	end

	if not matches then
		error({"module-errors.parameter-invalid-value", module_type, key, value}, 5)
	end
end

---Validates the parameters of the module
---@param module GuiModuleDef
---@param params ModuleParameterDict
local function validate_module_params(module, params)
	local parameter_description = module.parameters
	local module_type = module.module_type
	---@type {[string]:ModuleParameterDef}
	local missing = {} -- mark every paramtere as 'missing'
	for key, value in pairs(parameter_description) do
		missing[key] = value
	end

	-- Validate each present parameter
	for key, value in pairs(params) do
		if key == "type" or key == "module_type" then goto continue end
		missing[key] = nil -- mark as not missing
		local acceptable = parameter_description[key]

		-- Error on extra parameters
		if not acceptable then
			error({"module-errors.parameter-extra", module_type, key}, 4) -- TODO: Test all error messages
		end

		-- Error on wrong parameter type
		type_validation(key, value, acceptable.type, module_type)

		-- Error when a string and doesn't match an enum
		enum_validation(key, value, acceptable.enum, module_type)

		-- Additional parameter checking possible?
		-- Might grow as the parameters's fields expands
    ::continue::
	end

	-- Error for missing required parameters
	for key, value in pairs(missing) do
		if not value.is_optional then
			error({"gui-errors.parameter-missing", module.module_type, key}, 4)
		end
	end
end

return validate_module_params