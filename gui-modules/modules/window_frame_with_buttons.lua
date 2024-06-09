local library = {}

-- Taken from the flib test suite
--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler function
local function frame_action_button(name, sprite, tooltip, handler)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    handler = handler,
  }
end

local function config_button(name, handler)
	return frame_action_button(name, "flib_settings", { "gui.flib-settings" }, handler)
end
local function pin_button(name, handler)
	return frame_action_button(name, "flib_pin", { "gui.flib-keep-open" }, handler)
end
local function close_button(name, handler)
	return frame_action_button(name, "utility/close", { "gui.close-instruction" }, handler)
end

-- local function close_button(name)
-- 	return {
-- 		type = "sprite-button",
-- 		name = name,
-- 		style = "close_button",
-- 		sprite = "utility/close_white",
-- 		hovered_sprite = "utility/close_black",
-- 		clicked_sprite = "utility/close_black",
-- 	}
-- end

---@class frameWithButtonsParams
---@field name string The name of the root frame
---@field title LocalisedString The title of the frame
---@field window_closed_handler fun(e) The handler for `on_gui_closed`
---@field close_name string The name of the close button
---@field close_handler fun(e) The handler of the close button
---@field pin_name string The name of the pin button
---@field pin_handler fun(e) The handler of the pin button
---@field config_name string The name of the config button
---@field config_handler fun(e) The handler of the config button
---@field children GuiElemDef The element that is contained within the frame
---Creates the frame for a window with an exit button
---@param params frameWithButtonsParams
---@return GuiElemDef
function library.frame_with_buttons(params)
	if not params.pin_name ~= not params.pin_handler then
		error({"library-errors.only-one-nil", {"library-errors.pin-param"}}, 2)
	end
	if not params.config_name ~= not params.config_handler then
		error({"library-errors.only-one-nil", {"library-errors.config-param"}}, 2)
	end
	if not params.close_name ~= not params.close_handler then
		error({"library-errors.only-one-nil", {"library-errors.close-param"}}, 2)
	end
	return {
		type = "frame", name = params.name,
		visible = false, elem_mods = { auto_center = true },
		handler = {[defines.events.on_gui_closed] = params.window_closed_handler},
		children = {
			{
				type = "flow", direction = "vertical",
				children = {
					{
						type = "flow", style = "flib_titlebar_flow",
						direction = "horizontal", drag_target = params.name,
						children = {
							{
								type = "label", style = "frame_title",
								caption = params.title, ignored_by_interaction = true
							},
							{
								type = "empty-widget", style = "flib_titlebar_drag_handle",
								ignored_by_interaction = true,
							},
							params.pin_name and pin_button(params.pin_name, params.pin_handler) or {},
							params.config_name and config_button(params.config_name, params.config_handler) or {},
							params.close_name and close_button(params.close_name, params.close_handler) or {},
						}
					},
					{
						type = "flow", style = "inset_frame_container_horizontal_flow",
						direction = "horizontal",
						children = params.children
					}
				}
			}
		}
	}
end

return library