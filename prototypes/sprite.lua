--- Taken from flib

local fab = "__gui-modules__/graphics/frame-action-icons.png"


data:extend{
	{ type = "sprite", name = "modules_pin_black", filename = fab, position = { 0, 0 }, size = 32, flags = { "gui-icon" } },
	{ type = "sprite", name = "modules_pin_white", filename = fab, position = { 32, 0 }, size = 32, flags = { "gui-icon" } },
	{
		type = "sprite",
		name = "modules_pin_disabled",
		filename = fab,
		position = { 64, 0 },
		size = 32,
		flags = { "gui-icon" },
	},
	{
		type = "sprite",
		name = "modules_settings_black",
		filename = fab,
		position = { 0, 32 },
		size = 32,
		flags = { "gui-icon" },
	},
	{
		type = "sprite",
		name = "modules_settings_white",
		filename = fab,
		position = { 32, 32 },
		size = 32,
		flags = { "gui-icon" },
	},
	{
		type = "sprite",
		name = "modules_settings_disabled",
		filename = fab,
		position = { 64, 32 },
		size = 32,
		flags = { "gui-icon" },
	},
}