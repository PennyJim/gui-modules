local module = {module_type = "editable_label", handlers = {}}

---@class WindowState.editable_label : WindowState
-- Where custom fields would go

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
	edit_button = "editable_label.edit_button",
	confirm = "editable_label.confirm",
	cancel = "editable_label.cancel"
}

---@class editableLabelDef : ModuleDef
---@field default_caption LocalisedString
---@field confirm_handler string?
-- where LuaLS parameter definitons go
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	default_caption = {is_optional = false, type = {"string","table"}},
	confirm_handler = {is_optional = true, type = {"string"}},
}

---Creates the frame for a window with an exit button
---@param params editableLabelDef
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
				handler = {
					[defines.events.on_gui_confirmed]=handler_names.confirm,
					[defines.events.on_gui_closed]=handler_names.cancel, -- FIXME: not the right event. 
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

---Handles someone starting to rename their label
---@param self WindowState.editable_label
---@param namespace string
---@param EventData GuiEventData
module.handlers[handler_names.edit_button] = function (self, namespace, EventData)
	local module = EventData.element.parent --[[@as LuaGuiElement]]
	local label = module.children[1]
	local textfield = module.children[2]
	local button = module.children[3]

	if label.visible then
		label.visible = false
		textfield.visible = true
		textfield.focus()
		button.tooltip = {"gui-edit-label.save-label"}
	else
		return textfield, defines.events.on_gui_confirmed
	end
end

---Handles someone confirming their renaming of the label
---@param self WindowState.editable_label
---@param namespace string
---@param EventData GuiEventData
module.handlers[handler_names.confirm] = function (self, namespace, EventData)
	local module = EventData.element.parent --[[@as LuaGuiElement]]
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
---Handles someone canceling their renaming of the label
---@param self WindowState.editable_label
---@param namespace string
---@param EventData GuiEventData
module.handlers[handler_names.cancel] = function (self, namespace, EventData)
	local module = EventData.element.parent --[[@as LuaGuiElement]]
	local label = module.children[1]
	local textfield = module.children[2]
	local button = module.children[3]

	local old_text = label.caption
	if old_text == label.tabs.default_caption then
		old_text = ""
	end
	---@cast old_text string
	textfield.text = old_text
	label.visible = true
	textfield.visible = false
	button.tooltip = {"gui-edit-label.edit-label"}
end

return module --[[@as GuiModuleDef]]