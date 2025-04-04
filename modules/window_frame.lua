---@type modules.GuiModuleDef
---@diagnostic disable-next-line: missing-fields
local module = {
	module_type = "window_frame",
	handlers = {}
}

---@class WindowState.window_frame : modules.WindowState
-- Where custom fields would go

---WindowState.my_module
---@param state table
module.setup_state = function(state)
	-- Make visually pinned
  if state.pinned then
    state.elems.window_close_button.tooltip = { "gui.close" }
    state.elems.pin_button.sprite = "flib_pin_black"
    state.elems.pin_button.style = "flib_selected_frame_action_button"
  end
end
-- FIXME: Make sure it can do everything a frame can

local handler_names = {
	pin = "window_frame.pin",
}

---@alias (partial) modules.types
---| "window_frame"
---@alias (partial) modules.ModuleElems
---| modules.WindowFrameElem
---@class modules.WindowFrameElem
---@field module_type "window_frame"
---@field args modules.WindowFrameArgs

---@class modules.WindowFrameArgs
-- where LuaLS parameter definitons go
---@field name string The name of the root frame
---@field title LocalisedString The title of the frame
---@field has_pin_button boolean? Whether or not to add the pin button
---@field has_close_button boolean? Whether or not to add the close button
---@field draggable boolean?
---@field children modules.GuiElemDef[] The element that is contained within the frame
---@field style string? The style of the root frame
---@field style_mods LuaStyle? Modifications to the style of the root frame
---@type ModuleParameterDict
module.parameters = {
	name = {is_optional = false, type = {"string"}},
	title = {is_optional = false, type = {"string","table"}},
	-- has_config_button = "boolean", -- TODO: add the necessary fields or split off into a separate module
	has_pin_button = {is_optional = true, type = {"boolean"}, default = false},
	has_close_button = {is_optional = true, type = {"boolean"}, default = false},
	draggable = {is_optional = true, type = {"boolean"}, default = false},
	children = {is_optional = false, type = {"table"}},
	style = {is_optional = true, type = {"string"}},
	style_mods = {is_optional = true, type = {"table"}},
}

---Creates the frame for a window with an exit button
---@param params modules.WindowFrameArgs
function module.build_func(params)
	params.draggable = params.draggable ~= false
	return {
		args = {
			type = "frame", name = params.name,
			visible = false, style = params.style
		},
---@diagnostic disable-next-line: missing-fields
		elem_mods = { auto_center = true },
		handler = {[defines.events.on_gui_closed] = "close"},
		style_mods = params.style_mods,
		children = {{
			args = {
				type = "flow", direction = "vertical",
			},
			children = {
				{ -- The titlebar
					args = {
						type = "flow", style = "flib_titlebar_flow",
						direction = "horizontal",
					},
					drag_target = params.draggable and params.name or nil,
					children = {
						{args={ -- Title
							type = "label", style = "frame_title",
							caption = params.title, ignored_by_interaction = true
						}},
						{args={ -- Drag handle
							type = "empty-widget", style = params.draggable and "flib_titlebar_drag_handle" or "flib_horizontal_pusher",
							ignored_by_interaction = true,
						}},
						-- params.has_config_button and {args={ -- Config button
						-- 		type = "sprite-button", style = "frame_action_button",
						-- 		name = "config_button", tooltip = {"gui.flib-settings"},
						-- 		sprite = "flib_settings_white", hovered_sprite = "flib_settings_black",
						-- 	},
						-- 	handler = params.config_handler,
						-- } or nil,
						params.has_pin_button and {args={ -- Pin button
								type = "sprite-button", style = "frame_action_button",
								name = "pin_button", tooltip = {"gui.flib-keep-open"},
								sprite = "flib_pin_white", hovered_sprite = "flib_pin_black",
							},
							handler = handler_names.pin,
						} or nil,
						params.has_close_button and {args={ -- Close button
								type = "sprite-button", style = "frame_action_button",
								name = "window_close_button", tooltip = {"gui.close-instruction"},
								sprite = "utility/close",
						},
							handler = "hide",
						} or nil,
					}
				},
				{ -- The flow for the contents
					args = {
						type = "flow", style = "inset_frame_container_horizontal_flow",
						direction = "horizontal",
					},
					children = params.children
				}
			}
		}}
	} --[[@as modules.GuiSimpleElemDef]]
end

---Handles the pinning of the window
---@param state WindowState.window_frame
module.handlers[handler_names.pin] = function (state)
  state.pinned = not state.pinned
  if state.pinned then
    state.elems.window_close_button.tooltip = { "gui.close" }
    state.elems.pin_button.sprite = "flib_pin_black"
    state.elems.pin_button.style = "flib_selected_frame_action_button"
    if state.player.opened == state.root then
			state.pinning = true
      state.player.opened = nil
    end
  else
    state.elems.window_close_button.tooltip = { "gui.close-instruction" }
    state.elems.pin_button.sprite = "flib_pin_white"
    state.elems.pin_button.style = "frame_action_button"
		if state.opened and state.player.opened == state.opened then
			state.pinning = true
		end
    state.player.opened = state.root
  end
end

return module