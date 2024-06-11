local module = {module_type = "window_frame", handlers = {}}

---@class WindowState.window_frame : WindowState
-- Where custom fields would go

local handler_names = {
	pin = "window_frame.pin",
}

---@class WindowFrameButtonsParams : ModuleParams
---@field name string The name of the root frame
---@field title LocalisedString The title of the frame
---@field has_pin_button boolean? Whether or not to add the pin button
---@field has_close_button boolean? Whether or not to add the close button
---@field children GuiElemDef The element that is contained within the frame
---@type ModuleParameterDict
module.parameters = {
	name = {is_optional = false, type = {"string"}},
	title = {is_optional = false, type = {"string"}},
	-- has_config_button = "boolean", -- TODO: add the necessary fields or split off into a separate module
	has_pin_button = {is_optional = true, type = {"boolean"}},
	has_close_button = {is_optional = true, type = {"boolean"}},
	children = {is_optional = false, type = {"table"}},
}

---Creates the frame for a window with an exit button
---@param params WindowFrameButtonsParams
---@return GuiElemDef
function module.build_func(params)
	return {
		type = "frame", name = params.name,
---@diagnostic disable-next-line: missing-fields
		visible = false, elem_mods = { auto_center = true },
		handler = {[defines.events.on_gui_closed] = "close"},
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
							-- params.has_config_button and {
							-- 	type = "module", module_type = "frame_action_button",
							-- 	name = "config_button", tooltip = {"gui.flib-settings"},
							-- 	sprite = "flib_settings", handler = params.config_handler
							-- } or {},
							params.has_pin_button and {
								type = "module", module_type = "frame_action_button",
								name = "pin_button", tooltip = {"gui.flib-keep-open"},
								sprite = "flib_pin", handler = handler_names.pin
							} or {},
							params.has_close_button and {
								type = "module", module_type = "frame_action_button",
								name = "window_close_button", tooltip = {"gui.close-instruction"},
								sprite = "utility/close", handler = "hide"
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
	} --[[@as GuiElemModuleDef]]
end

---Handles the pinning of the window
---@param self WindowState.window_frame
module.handlers[handler_names.pin] = function (self)
  self.pinned = not self.pinned
  if self.pinned then
    self.elems.window_close_button.tooltip = { "gui.close" }
    self.elems.pin_button.sprite = "flib_pin_black"
    self.elems.pin_button.style = "flib_selected_frame_action_button"
    if self.player.opened == self.root then
      self.player.opened = nil
    end
  else
    self.elems.window_close_button.tooltip = { "gui.close-instruction" }
    self.elems.pin_button.sprite = "flib_pin_white"
    self.elems.pin_button.style = "frame_action_button"
    self.player.opened = self.root
  end
end

return module --[[@as GuiModuleDef]]