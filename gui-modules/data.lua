local modules = {}
local validate_module = {}
---@type table<type,true>
local type_lookup = {
	-- ["nil"] = true, -- Just mark as optional
	["number"] = true,
	["string"] = true,
	["boolean"] = true,
	["table"] = true,
	-- ["function"] = true, -- Handlers should be registered and passed a strings
	-- I could be convinced to allow passing functions, but you have to have a *good* reason
	-- ["thread"] = true, -- Should not be possible
	-- ["userdata"] = true, -- Don't all LuaObjects have table wrappers?
}
---@type table<type,true>
local enum_type_lookup = {
	["string"] = true
	-- Extensible for if enums of other types should be allowed
	-- I'm *this* close to already doing that, but I can't really think of a good reason to
}

---Validates the modules and throws errors on invalid modules
---*now* rather than letting an someone try and use it
---@param name string
---@param definition GuiModuleDef
function validate_module.module(name, definition)
	if modules[definition.module_type] then
		error{"gui-errors.module-already-exists", name}
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

	for key, definition in pairs(parameters) do
		validate_module.param(name, key, definition)
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

---Validates the parameters
---@param name string
---@param key string
---@param definition ModuleParameterDef
function validate_module.param(name, key, definition)
	if type(key) ~= "string" then
		error{"gui-errors.module-param-key", name, key}
	end
	if type(definition) ~= "table" then
		error{"gui-errors.module-param-value", name, key}
	end
	local optional = definition.is_optional
	if type(optional) ~= "boolean" then
		error{"gui-errors.module-param-optional", name, key}
	end

	local valid_type_table = definition.type
	if type(definition.type) ~= "table" then
		error{"gui-errors.module-param-type", name, key}
	end
	local can_enum,valid_type_lookup = false,{}
	for index, type_string in pairs(valid_type_table) do
		if not valid_type_lookup[type_string] then
			error{"gui-errors.module-param-invalid-type", name, key, index, type_string}
		end
		if not can_enum and enum_type_lookup[type_string] then
			can_enum = true
		end
		valid_type_lookup[type_string] = true
	end

	local enum = definition.enum
	if not can_enum and enum then
		error{"gui-errors.module-param-extra-enum", name, key}
	else
		if type(enum) ~= "table" then
			error{"gui-errors.module-param-enum"}
		end

		for index, value in pairs(enum) do
			local value_type = type(value)
			if not enum_type_lookup[value_type] or not valid_type_lookup[value_type] then
				error{"gui-errors.module-param-invalid-enum", name, key, index, value_type}
			end
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