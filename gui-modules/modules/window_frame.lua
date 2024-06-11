local module = {module_type = "window_frame", handlers = {} --[[@as GuiModuleEventHandlers]]}

---@class WindowState.window_frame : WindowState
-- Where custom fields would go

local handler_names = {
	pin = "window_frame.pin",
}
-- FIXME: Make sure it can do everything a frame can

---@class WindowFrameButtonsDef : ModuleDef
---@field module_type "window_frame"
-- where LuaLS parameter definitons go
---@field name string The name of the root frame
---@field title LocalisedString The title of the frame
---@field has_pin_button boolean? Whether or not to add the pin button
---@field has_close_button boolean? Whether or not to add the close button
---@field draggable boolean?
---@field children GuiElemModuleDef[] The element that is contained within the frame
---@field style string? The style of the root frame
---@field style_mods LuaStyle? Modifications to the style of the root frame
---@type ModuleParameterDict
module.parameters = {
	name = {is_optional = false, type = {"string"}},
	title = {is_optional = false, type = {"string"}},
	-- has_config_button = "boolean", -- TODO: add the necessary fields or split off into a separate module
	has_pin_button = {is_optional = true, type = {"boolean"}},
	has_close_button = {is_optional = true, type = {"boolean"}},
	draggable = {is_optional = true, type = {"boolean"}},
	children = {is_optional = false, type = {"table"}},
	style = {is_optional = true, type = {"string"}},
	style_mods = {is_optional = true, type = {"table"}},
}

---Creates the frame for a window with an exit button
---@param params WindowFrameButtonsDef
---@return GuiElemDef
function module.build_func(params)
	params.draggable = params.draggable ~= false
	return {
		type = "frame", name = params.name,
---@diagnostic disable-next-line: missing-fields
		visible = false, elem_mods = { auto_center = true },
		handler = {[defines.events.on_gui_closed] = "close"},
		style = params.style, style_mods = params.style_mods,
		children = {
			{
				type = "flow", direction = "vertical",
				children = {
					{ -- The titlebar
						type = "flow", style = "flib_titlebar_flow",
						direction = "horizontal", drag_target = params.draggable and params.name or nil,
						children = {
							{ -- Title
								type = "label", style = "frame_title",
								caption = params.title, ignored_by_interaction = true
							},
							{ -- Drag handle
								type = "empty-widget", style = params.draggable and "flib_titlebar_drag_handle" or "flib_horizontal_pusher",
								ignored_by_interaction = true,
							},
							-- params.has_config_button and { -- Config button
							-- 	type = "module", module_type = "frame_action_button",
							-- 	name = "config_button", tooltip = {"gui.flib-settings"},
							-- 	sprite = "flib_settings", handler = params.config_handler
							-- } or {},
							params.has_pin_button and { -- Pin button
								type = "module", module_type = "frame_action_button",
								name = "pin_button", tooltip = {"gui.flib-keep-open"},
								sprite = "flib_pin", handler = handler_names.pin
							} or {},
							params.has_close_button and { -- Close button
								type = "module", module_type = "frame_action_button",
								name = "window_close_button", tooltip = {"gui.close-instruction"},
								sprite = "utility/close", handler = "hide"
							} or {},
						}
					},
					{ -- The flow for the contents
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
			self.pinning = true
      self.player.opened = nil
    end
  else
    self.elems.window_close_button.tooltip = { "gui.close-instruction" }
    self.elems.pin_button.sprite = "flib_pin_white"
    self.elems.pin_button.style = "frame_action_button"
		if self.opened and self.player.opened == self.opened then
			self.pinning = true
		end
    self.player.opened = self.root
  end
end

return module --[[@as GuiModuleDef]]