---Adds the module to the list of ones considered by gui-modules
---@param name string
---@param filename string
---@return table
function module_add(name, filename)
	return {
		type = "string-setting",
		name = "gui_module_add_"..name,
		setting_type = "startup",
		default_value = filename,
		hidden = true,
	}
end
local function main_module_add(name)
	return module_add(name, "__gui-modules__.modules."..name)
end

data:extend{
	main_module_add("frame_action_button"),
	main_module_add("window_frame"),
}