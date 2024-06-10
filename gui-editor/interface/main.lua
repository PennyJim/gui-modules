require("__gui-modules__.gui").new{
	namespace = "testing-2", version = 0,
	shortcut = "visual-editor-2",
	root = "screen",
	definition = {
		{
			type = "module",
			module_type = "window_frame",
			name = "testing-2", title = "Testing",
			has_close_button = true,
			children = {
				{
					type = "label",
					caption = "This is to test that it works :P Alt"
				}
			}
		}
	}
}--[[@as GuiWindowDef]]{
	-- other Handlers go here
}

require("__gui-modules__.gui").new{
	namespace = "testing", version = 0,
	shortcut = "visual-editor", custominput = "visual-editor",
	root = "screen",
	definition = {
		{
			type = "module",
			module_type = "window_frame",
			name = "testing", title = "Testing",
			has_close_button = true,
			children = {
				{
					type = "label",
					caption = "This is to test that it works :P v2"
				}
			}
		}
	}
}--[[@as GuiWindowDef]]{
	-- other Handlers go here
}