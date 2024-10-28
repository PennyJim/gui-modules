---@class FrameActionButtonDef
---@field name string
---@field sprite string
---@field tooltip LocalisedString
---@field handler string
---@field append boolean

---@type modules.GuiModuleDef
return {
	module_type = "frame_action_button",
	parameters = { -- TODO: make more sophisticated so the editor can turn some fields into drop-downs?
		name = {is_optional = false, type = {"string"}},
		sprite = {is_optional = false, type = {"string"}},
		tooltip = {is_optional = true, type = {"table","string"}},
		handler = {is_optional = true, type = {"string"}}, -- The name of the handler
		append = {is_optional = true, type = {"boolean"}},
	},
	---@param params FrameActionButtonDef
	---@return modules.GuiElemModuleDef
	build_func = function(params)
		return {
			type = "sprite-button",
			name = params.name,
			style = "frame_action_button",
			sprite = params.append and params.sprite.. "_white" or params.sprite,
			hovered_sprite = params.append and params.sprite.. "_black" or params.sprite,
			clicked_sprite = params.append and params.sprite.. "_black" or params.sprite,
			tooltip = params.tooltip,
			handler = params.handler,
		}
	end,
	handlers = {}
}