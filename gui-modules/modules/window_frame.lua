local module = {module_type = "window_frame", handlers = {}}

---@class WindowState.window_frame : WindowState
-- Where custom fields would go

local handler_names = {
	close = "window_frame:close",
	pin = "window_frame:pin",
}

-- local function config_button(name, handler)
-- 	return frame_action_button(name, "flib_settings", { "gui.flib-settings" }, handler)
-- end
-- local function pin_button(name, handler)
-- 	return frame_action_button(name, "flib_pin", { "gui.flib-keep-open" }, handler)
-- end
-- local function close_button(name, handler)
-- 	return frame_action_button(name, "utility/close", { "gui.close-instruction" }, handler)
-- end

---@class frameWithButtonsParams
---@field name string The name of the root frame
---@field title LocalisedString The title of the frame
---@field has_pin_button boolean Whether or not to add the pin button
---@field has_close_button boolean Whether or not to add the close button
---@field children GuiElemDef The element that is contained within the frame

module.parameters = {
	name = "string",
	title = "string",
	-- has_config_button = "boolean", -- TODO: add the necessary fields or split off into a separate module
	has_pin_button = "boolean",
	has_close_button = "boolean",
	children = "table",
}

---Creates the frame for a window with an exit button
---@param params frameWithButtonsParams
---@return GuiElemDef
function module.build_func(params)
	return {
		type = "frame", name = params.name,
		visible = false, elem_mods = { auto_center = true },
		handler = {[defines.events.on_gui_closed] = handler_names.close},
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
							-- params.config_name and config_button(params.config_name, params.config_handler) or {},
							params.has_pin_button and {
								type = "module", module_type = "frame_action_button",
								sprite = "utility/close", tooltip = {"gui.flib-keep-open"},
								handler = handler_names.pin
							} or {},
							params.has_close_button and {
								type = "module", module_type = "frame_action_button",
								sprite = "flib_pin", tooltip = {"gui.close-instruction"},
								handler = "hide"
							} or {},
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

---Handles the window closing
---@param self WindowState.window_frame
module.handlers[handler_names.close] = function (self)
  if self.pinned then
    return
  end
	self.player.opened = nil
end
---Handles the pinning of the window
---@param self WindowState.window_frame
module.handlers[handler_names.pin] = function (self)
  self.pinned = not self.pinned
  if self.pinned then
    self.elems.close_button.tooltip = { "gui.close" }
    self.elems.pin_button.sprite = "flib_pin_black"
    self.elems.pin_button.style = "flib_selected_frame_action_button"
    if self.player.opened == self.elems.flib_todo_window then
      self.player.opened = nil
    end
  else
    self.elems.close_button.tooltip = { "gui.close-instruction" }
    self.elems.pin_button.sprite = "flib_pin_white"
    self.elems.pin_button.style = "frame_action_button"
    self.player.opened = self.elems.flib_todo_window
  end
end

return module --[[@as GuiModuleDef]]