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

--- So I don't have to keep calling string.format directly
local real_error = error
local function error(...) real_error(string.format(...)) end

---Validates the modules and throws errors on invalid modules
---*now* rather than letting an someone try and use it
---@param name string
---@param definition GuiModuleDef
function validate_module.module(name, definition)
	if modules[definition.module_type] then
		error("the '%s' module already exists", name)
	end
	modules[definition.module_type] = true

	if type(definition.build_func) ~= "function" then
		error("The '%s' module needs a `build_func`", name)
	end
	if definition.setup_state and type(definition.setup_state) ~= "function" then
		error("The '%s' module's state initialization needs to be a function", name)
	end
	local handlers = definition.handlers
	if type(handlers) ~= "table" then
		error("The '%s' module needs a handler table, even if it's empty", name)
	end
	validate_module.handlers(name, handlers)
	local parameters = definition.parameters
	if type(parameters) ~= "table" then
		error("The '%s' module needs a parameter table, even if it's empty", name)
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
		if type(key) == "table" then
			error("The '%s' module has a table for its handler key. That is unusable and you should feel ashamed (if it was intentional)", name)
		end
		if type(handler) ~= "function" then
			error("The '%s' module has a non-function as its handler for '%s'", name, key)
		end
	end
end

---Validates the parameters
---@param name string
---@param key string
---@param definition ModuleParameterDef
function validate_module.param(name, key, definition)
	if type(key) ~= "string" then
		error("The '%s' module's parameter keys should all be strings, not '%s'", name, serpent.block(key))
	end
	if type(definition) ~= "table" then
		error("The '%s' module's '%s' parameter needs to be a table defining it", name, key)
	end
	local optional = definition.is_optional
	if type(optional) ~= "boolean" then
		error("The '%s' module's '%s' parameter needs to define `is_optional` with a boolean", name, key)
	end

	local valid_type_table = definition.type
	if type(definition.type) ~= "table" then
		error("The '%s' module's '%s' parameter need to define its type with an array", name, key)
	end
	local can_enum,valid_type_lookup = false,{}
	for index, type_string in pairs(valid_type_table) do
		if not type_lookup[type_string] then
			error("The '%s' module's '%s' parameter's type array has '%s', an invalid value, at index '%s'", name, key, type_string, serpent.block(index))
		end
		if not can_enum and enum_type_lookup[type_string] then
			can_enum = true
		end
		valid_type_lookup[type_string] = true
	end

	local enum,enum_values = definition.enum,{}
	if not can_enum and enum then
		error("The '%s' module's '%s' parameter has an enum when its types are not enumable", name, key)
	elseif enum then
		if type(enum) ~= "table" then
			error("The '%s' module's '%s' parameter's enum needs to be an array of values", name, key)
		end

		for index, value in pairs(enum) do
			local value_type = type(value)
			if not enum_type_lookup[value_type] or not valid_type_lookup[value_type] then
				error("The '%s' module's '%s' parameter's enum has an invalid value of type '%s' at index '%s'", name, key, value_type, serpent.block(index))
			end
		end
	end

	local default = definition.default
	if default and not optional then
		error("The '%s' module's '%s' parameter has a default when it's not nillable", name, key)
	elseif default then
		local default_type = type(default)
		if not valid_type_lookup[default_type] then
			error("The '%s' module's '%s' parameter has a default of an invalid type", name, key)
			error{"gui-errors.module-param-invalid-default-type", name, key}
		end
		if enum and enum_type_lookup[default_type] then
			error("The '%s' module's '%s' parameter has a default not in the enum", name, key)
		end
	end
end

local prefix = "gui_module_add_"
for name, setting in pairs(settings.startup) do
	if name:find(prefix) then
		local setting_name = name:sub(prefix:len()+1)
		---@type GuiModuleDef
		local module = require(setting.value --[[@as string]])
		local module_name = module.module_type
		if type(module_name) ~= "string" then
			error("%s's module is missing a valid name", name)
		end
		if module_name ~= setting_name then
			log(string.format("The '%s' module was expected to be named '%s' based on the setting name", module_name, setting_name))
		end
		validate_module.module(module_name, module)
	end
end