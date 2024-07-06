---@class FrameActionButtonDef
---@field name string
---@field sprite string
---@field tooltip LocalisedString
---@field handler string

---@type GuiModuleDef
return {
	module_type = "frame_action_button",
	parameters = { -- TODO: make more sophisticated so the editor can turn some fields into drop-downs?
		name = {is_optional = false, type = {"string"}},
		sprite = {is_optional = false, type = {"string"}},
		tooltip = {is_optional = true, type = {"table","string"}},
		handler = {is_optional = true, type = {"string"}}, -- The name of the handler
	},
	---@param params FrameActionButtonDef
	---@return GuiElemModuleDef
	build_func = function(params)
		return {
			type = "sprite-button",
			name = params.name,
			style = "frame_action_button",
			sprite = params.sprite .. "_white",
			hovered_sprite = params.sprite .. "_black",
			clicked_sprite = params.sprite .. "_black",
			tooltip = params.tooltip,
			handler = params.handler,
		}
	end,
	handlers = {}
}