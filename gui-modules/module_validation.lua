---Validates the parameters of the module
---@param module GuiModuleDef
---@param params table
local function validate_module_params(module, params)
	local acceptable_description = module.parameters
	---@type {[string]:ModuleParameterDef}
	local missing = {} -- mark every paramtere as 'missing'
	for key, value in pairs(acceptable_description) do
		missing[key] = value
	end

	-- Validate each present parameter
	for key, value in pairs(params) do
		if key == "type" or key == "module_type" then goto continue end
		missing[key] = nil -- mark as not missing
		local acceptable = acceptable_description[key]

		-- Error on extra parameters
		if not acceptable then
			error({"module-errors.parameter-extra", module.module_type, key}, 4) -- TODO: Test all error messages
		end

		-- Error on wrong parameter type
		local is_valid_type = false
		for _, valid_type in pairs(acceptable.type) do
			if type(value) == valid_type then
				is_valid_type = true
				break
			end
		end
		if not is_valid_type then
			error({"module-errors.parameter-invalid-type", module.module_type, key, type(value)}, 4)
		end

		-- Error when a string and doesn't match an enum
		if acceptable.enum then
			local matches = false
			for _, valid_value in pairs(acceptable.enum) do
				if value == valid_value then
					matches = true
					break
				end
			end

			if not matches then
				error({"module-errors.parameter-invalid-value", module.module_type, key, value})
			end
		end

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