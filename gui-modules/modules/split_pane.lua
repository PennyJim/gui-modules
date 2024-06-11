local module = {module_type = "split_pane", handlers = {}}

---@class WindowState.my_module : WindowState
-- Where custom fields would go

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
}

---@class SplitPaneModuleParams : ModuleParams
-- where LuaLS parameter definitons go
---@field number_of_panes integer
---@field direction "horizontal"|"vertical"
---@field panes GuiElemModuleDef[]
---@field frame_styles string[]|string
---@field stretch_panes boolean?
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	number_of_panes = {is_optional = false, type = {"number"}},
	direction = {is_optional = false, type = {"string"}, enum = {"horizontal", "vertical"}},
	panes = {is_optional = false, type = {"table"}},
	frame_styles = {is_optional = true, type = {"string", "table"}},
	stretch_panes = {is_optional = true, type = {"boolean"}},
}

---Creates the frame for a window with an exit button
---@param params SplitPaneModuleParams
---@return GuiElemDef
function module.build_func(params)
	local panes = params.number_of_panes
	local styles = params.frame_styles or "inside_shallow_frame_with_padding"
	local style
	local pane_contents = params.panes
	if type(styles) == "string" then
		style = styles
	elseif #styles < panes then
		error{"module-errors.array-too-short", "frame_styles", panes, #styles}
	elseif #pane_contents < panes then
		error{"module-errors.array-too-short", "children", panes, #pane_contents}
	end

	local children = {}
	---@type LuaStyle?
	local child_style_mod = params.stretch_panes and {[params.direction.."ly_stretchable"] = true} or nil
	for i = 1, panes, 1 do
		children[i] = {
			type = "frame", style = style or styles[i],
			style_mods = child_style_mod,
			children = {pane_contents[i]}
		} --[[@as GuiElemModuleDef]]
	end
	return {
		type = "flow", direction = params.direction,
		style = "inset_frame_container_"..params.direction.."_flow",
		children = children
	}
end

-- How to define handlers
-- ---@param self WindowState.window_frame
-- module.handlers[handler_names.my_handler] = function (self)
-- 	-- Do stuff
-- end

return module --[[@as GuiModuleDef]]