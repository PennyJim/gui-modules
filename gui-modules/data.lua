local modules = {}
local validate_module = {}

---Validates the modules and throws errors on invalid modules
---*now* rather than letting an someone try and use it
---@param name string
---@param definition GuiModuleDef
function validate_module.module(name, definition)
	if modules[definition.module_type] then
		error({"gui-errors.module-already-exists", name}, 2)
	end
	modules[definition.module_type] = true

	local build_func = definition.build_func
	if not build_func or type(build_func) ~= "function" then
		error{"gui-errors.needs-build-func", name}
	end
	local handlers = definition.handlers
	if not handlers or type(handlers) ~= "table" then
		error{"gui-errors.needs-handler-table", name}
	end
	validate_module.handlers(name, handlers)
	local parameters = definition.parameters
	if not parameters or type(parameters) ~= "table" then
		error{"gui-errors.needs-parameter-table", name}
	end
end

---validates each handler is a function
---@param name string
---@param handlers GuiModuleEventHandlers
function validate_module.handlers(name, handlers)
	for key, handler in pairs(handlers) do
		if type(handler) ~= "function" then
			error{"gui-errors.handler-function", name, key}
		end
	end
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
		validate_module.module(module_name, module)
	end
end