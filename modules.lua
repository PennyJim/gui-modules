---@type {[modules.types]:modules.GuiModuleDef}
local modules = {}
local prefix = "gui_module_add_"

-- Grab the modules from startup settings
for name, setting in pairs(settings.startup) do
	if name:find(prefix) then
		---@type modules.GuiModuleDef
		local module = require(setting.value --[[@as string]])
		modules[module.module_type] = module
	end
end

return modules