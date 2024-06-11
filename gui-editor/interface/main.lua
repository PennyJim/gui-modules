---@type GuiElemModuleDef[]
local filler_children = {{
	type = "label", caption = "Filler"
}--[[@as GuiElemModuleDef]]}

---@type GuiElemModuleDef[]
local vert_pusher_children = {
	{
		type = "flow", direction = "vertical",
		children = {
			{
				type = "empty-widget",
				style = "flib_vertical_pusher"
			},
			{
				type = "label", caption = "Filler"
			},
			{
				type = "empty-widget",
				style = "flib_vertical_pusher"
			}
		}
	}
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
			has_close_button = true, has_pin_button = true,
			children = {
				{
					type = "module", module_type = "split_pane",
					number_of_panes = 2, direction = "horizontal",
					frame_styles = "invisible_frame",
					panes = {
						{{
							type = "module", module_type = "split_pane",
							number_of_panes = 5, direction = "vertical",
							panes = {
								filler_children,
								filler_children,
								filler_children,
								filler_children,
								filler_children
							}
						}},
						{{
							type = "module", module_type = "split_pane",
							number_of_panes = 3, direction = "vertical",
							panes = {
								filler_children,
								vert_pusher_children,
								filler_children
							}
						}}
					}
				} --[[@as SplitPaneModuleParams]]
			}
		} --[[@as WindowFrameButtonsParams]]
	}
}--[[@as GuiWindowDef]]{
	-- other Handlers go here
}