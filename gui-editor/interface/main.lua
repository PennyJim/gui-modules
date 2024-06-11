---@type GuiElemModuleDef
local filler_child = {
	type = "label", caption = "Filler"
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
			has_close_button = true, has_pin_button = true,
---@diagnostic disable-next-line: missing-fields
			style_mods = {natural_height = 10000, natural_width = 10000},
			children = {
				{
					type = "module", module_type = "split_pane",
					number_of_panes = 2, direction = "horizontal",
					frame_styles = "invisible_frame",
					panes = {
						{
							type = "module", module_type = "split_pane",
							number_of_panes = 5, direction = "vertical",
							stretch_panes = true,
							panes = {
								filler_child,
								filler_child,
								filler_child,
								filler_child,
								filler_child
							}
						},
						{
							type = "module", module_type = "split_pane",
							number_of_panes = 3, direction = "vertical",
							stretch_panes = true,
							panes = {
								filler_child,
								filler_child,
								filler_child
							}
						}
					}
				} --[[@as SplitPaneModuleParams]]
			}
		} --[[@as WindowFrameButtonsParams]]
	}
}--[[@as GuiWindowDef]]{
	-- other Handlers go here
}