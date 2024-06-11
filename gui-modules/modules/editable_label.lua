local module = {module_type = "editable_label", handlers = {} --[[@as GuiModuleEventHandlers]]}

---@class WindowState.editable_label : WindowState
-- Where custom fields would go

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
	edit_button = "editable_label.edit_button",
	confirm = "editable_label.confirm",
	cancel = "editable_label.cancel",
	focus = "editable_label.focus",
	unfocus = "editable_label.unfocus",
}

---@class EditableLabelDef : ModuleDef
---@field module_type "editable_label"
-- where LuaLS parameter definitons go
---@field default_caption LocalisedString
---@field confirm_handler string?
---@field reserve_space boolean?
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	default_caption = {is_optional = false, type = {"string","table"}},
	confirm_handler = {is_optional = true, type = {"string"}},
	reserve_space = {is_optional = true, type = {"boolean"}},
}

---Creates the frame for a window with an exit button
---@param params EditableLabelDef
---@return GuiElemDef
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
				type = "label", caption = params.default_caption,
				tags = {default_caption = params.default_caption},
				handler = {[defines.events.on_gui_confirmed]=params.confirm_handler}
			},
			{
				type = "textfield", visible = false,
				lose_focus_on_confirm = true,
				handler = {
					[defines.events.on_gui_confirmed]=handler_names.confirm,
					[defines.events.on_gui_closed]=handler_names.cancel,
					[handler_names.focus]=handler_names.focus, -- Fake functions because focus and unfocus don't exist (yet?)
					[handler_names.unfocus]=handler_names.unfocus,
				}
			},
			{
				type = "sprite-button", style = "mini_button_aligned_to_text_vertically_when_centered",
				tooltip = {"gui-edit-label.edit-label"}, sprite = "utility/rename_icon_small_black",
				handler = handler_names.edit_button
			}
		}
	} --[[@as GuiElemModuleDef]]
end

---@param self WindowState.editable_label
---@param elem LuaGuiElement
module.handlers[handler_names.edit_button] = function (self, elem)
	local module = elem.parent --[[@as LuaGuiElement]]
	local label = module.children[1]
	local textfield = module.children[2]
	local button = module.children[3]

	if label.visible then
		label.visible = false
		textfield.visible = true
		textfield.focus()
		button.tooltip = {"gui-edit-label.save-label"}
		return textfield, handler_names.focus
	else
		return textfield, defines.events.on_gui_confirmed
	end
end

---@param self WindowState.editable_label
---@param elem LuaGuiElement
module.handlers[handler_names.confirm] = function (self, elem)
	local module = elem.parent --[[@as LuaGuiElement]]
	local label = module.children[1]
	local textfield = module.children[2]
	local button = module.children[3]

	---@type LocalisedString
	local new_text = textfield.text
	if #new_text == 0 then
		new_text = label.tags.default_caption --[[@as LocalisedString]]
	end
	label.caption = new_text
	label.visible = true
	textfield.visible = false
	button.tooltip = {"gui-edit-label.edit-label"}
	self.opened = nil
	return label, defines.events.on_gui_confirmed
end
---@param self WindowState.editable_label
---@param elem LuaGuiElement
module.handlers[handler_names.cancel] = function (self, elem)
	if self.pinning then
		self.pinning = nil
		return
	end
	local module = elem.parent --[[@as LuaGuiElement]]
	local label = module.children[1]
	local textfield = module.children[2]
	local button = module.children[3]

	local old_text = label.caption
	if old_text == label.tags.default_caption then
		old_text = ""
	end
	---@cast old_text string
	textfield.text = old_text
	label.visible = true
	textfield.visible = false
	button.tooltip = {"gui-edit-label.edit-label"}
	return nil, handler_names.unfocus
end
---@param self WindowState.editable_label
---@param elem LuaGuiElement
module.handlers[handler_names.focus] = function (self, elem)
	local module = elem.parent --[[@as LuaGuiElement]]
	local textfield = module.children[2]

	self.opened = textfield
	if not self.player.opened then
		self.player.opened = textfield
	end
end
---@param self WindowState.editable_label
module.handlers[handler_names.unfocus] = function (self)
	self.opened = nil
end

return module --[[@as GuiModuleDef]]