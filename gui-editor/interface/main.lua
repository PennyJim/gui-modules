---@type GuiElemModuleDef
local filler_child = {
	type = "label", caption = "Filler",
	style_mods = {height = 400, width = 100}
}--[[@as GuiElemModuleDef]]

require("__gui-modules__.gui").new{
	namespace = "testing", version = 0,
	shortcut = "visual-editor", custominput = "visual-editor",
	root = "screen",
	definition = {
		{
			type = "module",
			module_type = "window_frame",
			name = "testing", title = "Testing",
			has_close_button = true, draggable = false,
---@diagnostic disable-next-line: missing-fields
			style_mods = {natural_height = 10000, natural_width = 10000},
			children = {
				{
					type = "module", module_type = "split_pane",
					number_of_panes = 3, direction = "horizontal",
					stretch_panes = false,
					frame_styles = {
						"inside_shallow_frame",
						"inside_shallow_frame",
						"inside_shallow_frame"
					},
					panes = {
						{
							type = "flow", direction = "vertical",
---@diagnostic disable-next-line: missing-fields
							style_mods = {vertically_stretchable = true, vertical_spacing = 0},
							children = {
								{
									type = "frame", style = "subheader_frame",
									children = {
										{
											-- type = "label",
											-- caption = "Root"
											type = "module", module_type = "editable_label",
											default_caption = "Root"
										} --[[@as editableLabelDef]],
										{
											type = "empty-widget", style = "flib_horizontal_pusher"
										}
									}
								},
								{
									type = "scroll-pane", 
									style = "scroll_pane_with_dark_background_under_subheader",
									style_mods = {vertically_stretchable = true, width = 300},
									-- style = "train_schedule_scroll_pane",
									children = {
										filler_child,
										filler_child,
										filler_child,
										filler_child,
										filler_child,
									}
								}
							}
						},
						{
							type = "scroll-pane", direction = "vertical",
							children = {
								filler_child,
							}
						},
						{
							type = "frame", style = "invisible_frame",
---@diagnostic disable-next-line: missing-fields
							style_mods = {
								vertically_stretchable = true,
								horizontally_stretchable = true,
							}
						}
					}
				} --[[@as SplitPaneModuleDef]]
			}
		} --[[@as WindowFrameButtonsDef]]
	}
}--[[@as GuiWindowDef]]{
	-- other Handlers go here
}