local library = {}

local function close_button(name)
	return {
		type = "sprite-button",
		name = name,
		style = "close_button",
		sprite = "utility/close_white",
		hovered_sprite = "utility/close_black",
		clicked_sprite = "utility/close_black",
	}
end

---Creates the frame for a window with an exit button
---@param name string The name of the root frame
---@param title LocalisedString The title of the frame
---@param close_name string The name of the close button
---@param children GuiElemDef The element that is contained within the frame
---@return GuiElemDef
function library.frame_with_exit(name, title, close_name, children)
	return {
		type = "frame",
		name = name,
		children = {
			{
				type = "flow", direction = "vertical",
				children = {
					{
						type = "flow", style = "flib_titlebar_flow",
						direction = "horizontal", drag_target = name,
						children = {
							{
								type = "label", style = "frame_title",
								caption = title, ignored_by_interaction = true
							},
							{
								type = "empty-widget", style = "flib_titlebar_drag_handle",
								ignored_by_interaction = true,
							},
							close_button(close_name)
						}
					},
					{
						type = "flow", style = "inset_frame_container_horizontal_flow",
						direction = "horizontal",
						children = children
					}
				}
			}
		}
	}
end

return library