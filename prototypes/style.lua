local styles = data.raw["gui-style"].default
-- Taken from flib

-- Buttons

styles.modules_selected_frame_action_button = {
  type = "button_style",
  parent = "frame_action_button",
  default_font_color = button_hovered_font_color,
  default_graphical_set = {
    base = { position = { 225, 17 }, corner_size = 8 },
    shadow = { position = { 440, 24 }, corner_size = 8, draw_type = "outer" },
  },
  hovered_font_color = button_hovered_font_color,
  hovered_graphical_set = {
    base = { position = { 369, 17 }, corner_size = 8 },
    shadow = { position = { 440, 24 }, corner_size = 8, draw_type = "outer" },
  },
  clicked_font_color = button_hovered_font_color,
  clicked_graphical_set = {
    base = { position = { 352, 17 }, corner_size = 8 },
    shadow = { position = { 440, 24 }, corner_size = 8, draw_type = "outer" },
  },
  -- Simulate clicked-vertical-offset
  top_padding = 1,
  bottom_padding = -1,
  clicked_vertical_offset = 0,
}

-- Empty Widgets

styles.modules_titlebar_drag_handle = {
  type = "empty_widget_style",
  parent = "draggable_space",
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = "on",
}

-- Pushers

styles.modules_horizontal_pusher = {
  type = "empty_widget_style",
  horizontally_stretchable = "on",
}
styles.modules_vertical_pusher = {
  type = "empty_widget_style",
  vertically_stretchable = "on",
}

-- Flows

styles.modules_indicator_flow = {
  type = "horizontal_flow_style",
  vertical_align = "center",
}
styles.modules_titlebar_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8,
}