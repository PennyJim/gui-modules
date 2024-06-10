local iron_gear = data.raw["item"]["iron-gear-wheel"]
data:extend{
	{
		type = "custom-input",
		name = "visual-editor",
		key_sequence = "SHIFT + T",
		action = "lua",
	},
	{
		type = "shortcut",
		name = "visual-editor",
		associated_control_input = "visual-editor",
		action = "lua",
		icon = {
			filename = iron_gear.icon,
			size = iron_gear.icon_size,
			mipmap_count = iron_gear.icon_mipmaps,
		},
		toggleable = true,
	},
	{
		type = "shortcut",
		name = "visual-editor-2",
		associated_control_input = "visual-editor",
		action = "lua",
		icon = {
			filename = iron_gear.icon,
			size = iron_gear.icon_size,
			mipmap_count = iron_gear.icon_mipmaps,
		},
		toggleable = true,
	}
}