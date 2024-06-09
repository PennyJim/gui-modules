---@type table<string,GuiModuleDef>
local modules = {}

---Registeres the module so any instance of the library can use it
---@param definition GuiModuleDef
local function register_module(definition)
	if modules[definition.module_type] then
		error({"library-errors.module-already-exists"}, 2)
	end
	if not definition.build_func or type(definition.build_func) ~= "function" then
		error({"library-errors.needs-build-func"}, 2)
	end
	if not definition.handlers then
		error({"library-errors.needs-handler-table"}, 2)
	end
	if not definition.parameters then
		error({"library-errors.needs-parameter-table"}, 2)
	end
	modules[definition.module_type] = definition
end

---Returns the definition of the requested module type
---@param module_type string
---@return GuiModuleDef?
local function get_module(module_type)
	return modules[module_type]
end


remote.add_interface("gui-modules", {
	["register-module"] = register_module,
	["get-module"] = get_module,
})