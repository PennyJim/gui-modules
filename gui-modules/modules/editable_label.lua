local module = {module_type = "editable_label", handlers = {} --[[@as GuiModuleEventHandlers]]}

---@class WindowState.editable_label : WindowState
-- Where custom fields would go
---@field was_pinned boolean? Whether or not the window was pinned before focus
---@field is_cancelable_focus boolean?

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
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	default_caption = {is_optional = false, type = {"string","table"}},
	confirm_handler = {is_optional = true, type = {"string"}},
}

---Creates the frame for a window with an exit button
---@param params EditableLabelDef
---@return GuiElemDef
function module.build_func(params)
	return {
		type = "flow", direction = "horizontal",
		style = "flib_indicator_flow",
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
	return label
end
---@param self WindowState.editable_label
---@param elem LuaGuiElement
module.handlers[handler_names.cancel] = function (self, elem)
	if not self.is_cancelable_focus then return end
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

	self.was_pinned = self.pinned
	self.pinned = true
	self.is_cancelable_focus = true
	self.player.opened = textfield
end
---@param self WindowState.editable_label
module.handlers[handler_names.unfocus] = function (self)
	self.pinned = self.was_pinned
	self.player.opened = self.pinned and nil or self.root
	self.was_pinned = nil
	self.is_cancelable_focus = nil
end

return module --[[@as GuiModuleDef]]