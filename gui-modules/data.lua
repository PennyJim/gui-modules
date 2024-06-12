local modules = {}

---Validates the modules and throws errors on invalid modules
---*now* rather than letting an someone try and use it
---@param definition GuiModuleDef
local function validate_module(definition)
	if modules[definition.module_type] then
		error({"gui-errors.module-already-exists"}, 2)
	end
	modules[definition.module_type] = true

	local build_func = definition.build_func
	if not build_func or type(build_func) ~= "function" then
		error({"gui-errors.needs-build-func"}, 2)
	end
	if not definition.handlers then
		error({"gui-errors.needs-handler-table"}, 2)
	end
	local parameters = definition.parameters
	if not parameters then
		error({"gui-errors.needs-parameter-table"}, 2)
	end
	modules[definition.module_type] = true
end

local prefix = "gui_module_add_"
for name, setting in pairs(settings.startup) do
	if name:find(prefix) then
		local module_name = name:sub(prefix:len()+1)
		---@type GuiModuleDef
		local module = require(setting.value --[[@as string]])
		if module.module_type ~= module_name then
			log{"gui-errors.different-expected-name", module_name, module.module_type}
		end
		validate_module(module)
	end
end