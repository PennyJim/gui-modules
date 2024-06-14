local gui = require("__gui-modules__.gui")

---@type GuiElemModuleDef
local filler_child = {
	type = "label", caption = "Filler",
	style_mods = {height = 400, width = 100}
}--[[@as GuiElemModuleDef]]
local test_handlers = {
	test_handler = function ()
		game.print("TEST!!")
	end
	-- other Handlers go here
}

local visual_editor = {
	namespace = "visual-editor", version = 0,
	shortcut = "visual-editor", custominput = "visual-editor",
	root = "screen",
	instances = {
		filler = filler_child
	},
	definition = {
		type = "module",
		module_type = "window_frame",
		name = "visual_editor", title = "GUI Editor",
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
										type = "module", module_type = "editable_label",
										default_caption = "Root", confirm_handler = "test_handler",
										style = "subheader_caption_label",
									} --[[@as EditableLabelDef]],
									{
										type = "empty-widget", style = "flib_horizontal_pusher"
									},
									{ type = "instantiable", instantiable_name = "filler"}
								}
							},
							{
								type = "scroll-pane", 
								style = "scroll_pane_with_dark_background_under_subheader",
								style_mods = {vertically_stretchable = true, width = 300},
								-- style = "train_schedule_scroll_pane",
								children = {
									{type = "instantiable", instantiable_name = "filler"},
									{type = "instantiable", instantiable_name = "filler"},
									{type = "instantiable", instantiable_name = "filler"},
									{type = "instantiable", instantiable_name = "filler"},
									{type = "instantiable", instantiable_name = "filler"},
								}
							}
						}
					},
					{
						type = "scroll-pane", direction = "vertical",
						children = {
							{type = "instantiable", instantiable_name = "filler"},
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
}--[[@as GuiWindowDef]]

local test = {
	namespace = "testing", version = 0,
	shortcut = "visual-editor",
	root = "screen",
	definition = {
		type = "module", module_type = "window_frame",
		name = "testing", title = "Testing",
		has_close_button = true, has_pin_button = true,
		children = {
			{
				type = "module", module_type = "editable_label",
				default_caption = "<unamed label>", confirm_handler = "test_handler",
				include_icon_picker = true,
				caption = "Named Label",
				style = "subheader_caption_label",
				style_mods = {width = 100},
				tooltip = "You can edit this!",
			} --[[@as EditableLabelDef]]
		}
	} --[[@as WindowFrameButtonsDef]]
}--[[@as GuiWindowDef]]

gui.new(visual_editor, test_handlers)
gui.new(test, test_handlers, nil, "visual-editor2")