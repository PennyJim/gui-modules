---@type GuiModuleDef
return {
	module_type = "frame_action_button",
	parameters = { -- TODO: make more sophisticated so the editor can turn some fields into drop-downs?
		name = "string",
		sprite = "string",
		tooltip = "table",
		handler = "string", -- The handler of the function
	},
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