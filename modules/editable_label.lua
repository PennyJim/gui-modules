local module = {module_type = "editable_label", handlers = {} --[[@as GuiModuleEventHandlers]]}

---@class WindowState.editable_label : modules.WindowState
-- Where custom fields would go

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
	edit_button = "editable_label.edit_button",
	icon_button = "editable_label.icon_button",
	confirm = "editable_label.confirm",
	cancel = "editable_label.cancel",
	focus = "editable_label.focus",
	unfocus = "editable_label.unfocus",
}

---@class EditableLabelDef : modules.ModuleDef
---@field module_type "editable_label"
-- where LuaLS parameter definitons go
---@field default_caption LocalisedString
---@field confirm_handler string?
---@field reserve_space boolean?
---@field include_icon_picker boolean?
-- label values
---@field caption LocalisedString?
---@field style string?
---@field style_mods LuaStyle?
---@field tooltip LocalisedString?
---@field elem_tooltip ElemID?
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	default_caption = {is_optional = false, type = {"string","table"}},
	confirm_handler = {is_optional = true, type = {"string"}},
	reserve_space = {is_optional = true, type = {"boolean"}, default = true},
	include_icon_picker = {is_optional = true, type = {"boolean"}, default = false},
	-- label values
	caption = {is_optional = true, type = {"string","table"}},
	style = {is_optional = true, type = {"string"}},
	style_mods = {is_optional = true, type = {"table"}},
	tooltip = {is_optional = true, type = {"string","table"}},
	elem_tooltip = {is_optional = true, type = {"table"}},
}

---Creates the frame for a window with an exit button
---@param params EditableLabelDef
---@return flib.GuiElemDef
function module.build_func(params)
	local reserve_space = params.reserve_space ~= false
	return {
		type = "flow", direction = "horizontal",
		style = "flib_indicator_flow",
---@diagnostic disable-next-line: missing-fields
		style_mods = {
			minimal_height = 28,
			natural_width = reserve_space and 220 or nil --[[@as integer]]
		},
		children = {
			{
				type = "label", caption = params.caption or params.default_caption,
				tags = {default_caption = params.default_caption},
				handler = {[defines.events.on_gui_confirmed]=params.confirm_handler},
				-- user specified:
				style = params.style, style_mods = params.style_mods,
				tooltip = params.tooltip,
				elem_tooltip = params.elem_tooltip,
			},
			{
				type = "textfield", visible = false,
				lose_focus_on_confirm = true, text = params.caption,
				clear_and_focus_on_right_click = true,
				handler = {
					[defines.events.on_gui_confirmed]=handler_names.confirm,
					[defines.events.on_gui_closed]=handler_names.cancel,
					[handler_names.focus]=handler_names.focus, -- Fake functions because focus and unfocus don't exist (yet?)
					[handler_names.unfocus]=handler_names.unfocus,
				}
			},
			-- With 2.0 adding include_icon_picker
			-- this section will be unnecessary.
			{
				type = "choose-elem-button", elem_type = "signal",
				style = "choose_chat_icon_button", visible = false,
---@diagnostic disable-next-line: missing-fields
				style_mods = {margin={1,0,0,-32}},
				tags = {is_enabled = params.include_icon_picker or false},
				handler = {[defines.events.on_gui_elem_changed]=handler_names.icon_button}
			},
			{
				type = "sprite-button", sprite = "utility/select_icon_black",
				visible = false, ignored_by_interaction = true,
				style = "choose_chat_icon_button",
---@diagnostic disable-next-line: missing-fields
				style_mods = {margin={1,0,0,-32}},
			},
			-- So remove it, and update the indexies in the handlers below to handle it.
			-- The number of items switching visibility also shrinks, so
			-- removing the open_editor function would be simple enough.
			{
				type = "sprite-button", style = "mini_button_aligned_to_text_vertically_when_centered",
				tooltip = {"gui-edit-label.edit-label"}, sprite = "utility/rename_icon",
				handler = handler_names.edit_button
			}
		}
	} --[[@as modules.GuiElemModuleDef]]
end

---@param module LuaGuiElement
---@param open boolean
local function open_editor(module, open)
	local elem_picker = module.children[3]
	module.children[1].visible = not open
	module.children[2].visible = open
	if elem_picker.tags.is_enabled then
		elem_picker.visible = open
		module.children[4].visible = open
	end
end

---@param state WindowState.editable_label
module.handlers[handler_names.edit_button] = function (state, elem)
	local module = elem.parent --[[@as LuaGuiElement]]
	local label = module.children[1]
	local textfield = module.children[2]
	local button = module.children[5]

	if label.visible then
		open_editor(module, true)
		textfield.focus()
		button.tooltip = {"gui-edit-label.save-label"}
		return textfield, handler_names.focus
	else
		return textfield, defines.events.on_gui_confirmed
	end
end
---@params state WindowState.editable_label
module.handlers[handler_names.icon_button] = function (state, elem)
	local module = elem.parent --[[@as LuaGuiElement]]
	local textfield = module.children[2]
	local elem_picker = module.children[3]

	local text = textfield.text
	local value = elem_picker.elem_value
	if value then
		-- textfield.text = text.."[img="..value.type.."."..value.name.."]"
		textfield.text = text.."["..value.type.."="..value.name.."]"
		elem_picker.elem_value = nil
	end
end

---@param state WindowState.editable_label
module.handlers[handler_names.confirm] = function (state, elem)
	local module = elem.parent --[[@as LuaGuiElement]]
	local label = module.children[1]
	local textfield = module.children[2]
	local button = module.children[5]

	---@type LocalisedString
	local new_text = textfield.text
	if #new_text == 0 then
		new_text = label.tags.default_caption --[[@as LocalisedString]]
	end
	label.caption = new_text
	open_editor(module, false)

	button.tooltip = {"gui-edit-label.edit-label"}
	state.opened = nil
	return label, defines.events.on_gui_confirmed
end
---@param state WindowState.editable_label
module.handlers[handler_names.cancel] = function (state, elem)
	if state.pinning then
		state.pinning = nil
		return
	end
	local module = elem.parent --[[@as LuaGuiElement]]
	local label = module.children[1]
	local textfield = module.children[2]
	local button = module.children[5]

	local old_text = label.caption
	if old_text == label.tags.default_caption then
		old_text = ""
	end
	---@cast old_text string
	textfield.text = old_text
	open_editor(module, false)
	button.tooltip = {"gui-edit-label.edit-label"}
	return nil, handler_names.unfocus
end
---@param state WindowState.editable_label
module.handlers[handler_names.focus] = function (state, elem)
	local module = elem.parent --[[@as LuaGuiElement]]
	local textfield = module.children[2]

	state.opened = textfield
	if not state.player.opened then
		state.player.opened = textfield
	end
end
---@param state WindowState.editable_label
module.handlers[handler_names.unfocus] = function (state)
	state.opened = nil
end

return module --[[@as modules.GuiModuleDef]]