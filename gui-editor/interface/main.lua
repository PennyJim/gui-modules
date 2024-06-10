require("__gui-modules__.gui").new{
	namespace = "testing", version = 0,
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