local gui = require("__gui-modules__.gui")

---@type GuiElemModuleDef
local filler_child = {
	type = "label", caption = "Filler",
---@diagnostic disable-next-line: missing-fields
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
						type = "frame", style = "inside_deep_frame_for_tabs",
						children = {
							{
								type = "tabbed-pane",
								children = {
---@diagnostic disable-next-line: missing-fields
									{
										tab = {
											type = "tab", caption = "Window"
										},
										content = {
											type = "frame",
											style = "window_content_frame_in_tabbed_panne",
											children = {
												type = "flow", direction = "vertical",
---@diagnostic disable-next-line: missing-fields
												style_mods = {vertically_stretchable = true, vertical_spacing = 0},
												children = {
													{
														type = "scroll-pane",
														style = "scroll_pane_with_dark_background_under_subheader",
---@diagnostic disable-next-line: missing-fields
														style_mods = {vertically_stretchable = true, width = 400},
														-- style = "train_schedule_scroll_pane",
														children = {
															{
																type = "frame", style = "train_schedule_station_frame",
																children = {
																	{
																		type = "button", style = "train_schedule_action_button"
																	},
																	{
																		type = "label", caption = "Name::Module:module_type", -- TODO: split into 2 labels
																	},
																	{
																		type = "empty-widget", style = "flib_horizontal_pusher"
																	},
																	{
																		type = "empty-widget", style = "draggable_space_in_train_schedule",
---@diagnostic disable-next-line: missing-fields
																		style_mods = {vertically_stretchable = true}
																	},
																	{
																		type = "button", style = "train_schedule_delete_button"
																	}
																}
															},
															{type = "instantiable", instantiable_name = "filler"},
															{type = "instantiable", instantiable_name = "filler"},
															{type = "instantiable", instantiable_name = "filler"},
															{type = "instantiable", instantiable_name = "filler"},
															{type = "instantiable", instantiable_name = "filler"},
														}
													}
												}
											}
										},
									},
---@diagnostic disable-next-line: missing-fields
									{
										tab = {
											type = "tab", caption = "instances"
										},
										content = {
											type = "frame",
											style = "window_content_frame_in_tabbed_panne",
											children = {
												{
													type = "flow", direction = "vertical",
													children = {
														{type = "instantiable", instantiable_name = "filler"},
														{type = "instantiable", instantiable_name = "filler"},
														{type = "instantiable", instantiable_name = "filler"},
														{type = "instantiable", instantiable_name = "filler"},
														{type = "instantiable", instantiable_name = "filler"},
													}
												},
											}
										}
									}
								}
							},
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
---@diagnostic disable-next-line: missing-fields
				style_mods = {width = 100},
				tooltip = "You can edit this!",
			} --[[@as EditableLabelDef]]
		}
	} --[[@as WindowFrameButtonsDef]]
}--[[@as GuiWindowDef]]

gui.new(visual_editor, test_handlers)
gui.new(test, test_handlers, nil, "visual-editor2")