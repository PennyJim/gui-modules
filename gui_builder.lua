---@class ModuleGuiLib.Builder
local builder = {
	---@type table<namespace,table<string,modules.GuiTaggedElemDef>>
	instances={}
}
local modules = require("__gui-modules__.modules")
local gui_events = require("__gui-modules__.gui_events")
local validate_module_params = require("__gui-modules__.module_validation")
local instances = builder.instances

--MARK: Modules


--- Add a new child or children to the given GUI element.
--- @param namespace namespace
--- @param parent LuaGuiElement
--- @param def modules.GuiElemDef
--- @param elems table<string, LuaGuiElement>
--- @return LuaGuiElement first The element that was created first;  the "top level" element.
local function build(namespace, parent, def, elems)
	---@type LuaGuiElement
	local element

	if def.instantiable_name then
		--MARK: Instance
		local name = def.instantiable_name
		def = instances[namespace][name]
		if not def then
			error{"gui-errors.invalid-instantiable", namespace, name}
		end

	elseif def.module_type then
		---@diagnostic disable-next-line: cast-type-mismatch
		---@cast def modules.ModuleElems
		--MARK: Module
		local module = modules[def.module_type]
		validate_module_params(module, def.args)
		gui_events.register(module.handlers, namespace)
		def = module.build_func(def.args)
	end
	---@cast def modules.GuiSimpleElemDef

	local args = def.args
	if args then
		--MARK: Handlers
		if def.handler then
			gui_events.convert_handler_names(namespace, def.handler, args)
			def.handler = nil
		end
		element = parent.add(args)
		if args.name and def.ref ~= false then
			local ref = def.ref or args.name --[[@as string]]
			elems[ref] = element
		end
		if def.elem_mods then
---@diagnostic disable-next-line: no-unknown
			for k, v in pairs(def.elem_mods) do
---@diagnostic disable-next-line: no-unknown
				element[k] = v
			end
		end
		if def.style_mods then
			local style = element.style
---@diagnostic disable-next-line: no-unknown
			for k, v in pairs(def.style_mods) do
---@diagnostic disable-next-line: no-unknown
				style[k] = v
			end
		end
		if def.drag_target then
			local target = elems[def.drag_target--[[@as string]]]
			if not target then
				error("Drag target not found: "..def.drag_target)
			end
			element.drag_target = target
		end

		if def.children then
			for _, child in pairs(def.children) do
				build(namespace, element, child, elems)
			end
		end

	elseif def.tab and def.content then
		local tab = build(namespace, parent, def.tab, elems)
		element = build(namespace, parent, def.content, elems)
		parent.add_tab(tab, element)

	else
		error("Invalid GUI element definition:"..serpent.block(def))
	end
	return element
end
builder.build = build

--- Add a new child or children to the given GUI element.
--- @param namespace namespace
--- @param def modules.GuiElemDef
--- @return modules.GuiTaggedElemDef
local function preprocess(namespace, def)
	if def.instantiable_name then
		--MARK: Instance
		local name = def.instantiable_name
		def = instances[namespace][name]
		if not def then
			error{"gui-errors.invalid-instantiable", namespace, name}
		end

	elseif def.module_type then
		---@diagnostic disable-next-line: cast-type-mismatch
		---@cast def modules.ModuleElems
		--MARK: Module
		local module = modules[def.module_type]
		validate_module_params(module, def.args)
		gui_events.register(module.handlers, namespace)
		def = module.build_func(def.args)
	end
	---@cast def modules.GuiSimpleElemDef

	local args = def.args
	if args then
		--MARK: Handlers
		if def.handler then
			gui_events.convert_handler_names(namespace, def.handler, args)
			def.handler = nil
		end
		if def.children then
			for index, child in pairs(def.children) do
				def.children[index] = preprocess(namespace, child)
			end
		end

	elseif def.tab and def.content then
		def.tab = preprocess(namespace, def.tab)
		def.content = preprocess(namespace, def.content)
	else
		error("Invalid GUI element definition:"..serpent.block(def))
	end

	---@cast def modules.GuiTaggedElemDef
	return def
end
builder.preprocess = preprocess

--- Add a new child or children to the given GUI element.
--- @param parent LuaGuiElement
--- @param def modules.GuiTaggedElemDef
--- @param elems table<string, LuaGuiElement>
--- @return LuaGuiElement first The element that was created first;  the "top level" element.
local function buildprocessed(parent, def, elems)
	---@type LuaGuiElement
	local element
	local args = def.args
	if args then
		element = parent.add(args)
		if args.name and def.ref ~= false then
			local ref = def.ref or args.name --[[@as string]]
			elems[ref] = element
		end
		if def.elem_mods then
---@diagnostic disable-next-line: no-unknown
			for k, v in pairs(def.elem_mods) do
---@diagnostic disable-next-line: no-unknown
			element[k] = v
			end
		end
		if def.style_mods then
---@diagnostic disable-next-line: no-unknown
			for k, v in pairs(def.style_mods) do
---@diagnostic disable-next-line: no-unknown
				element[k] = v
			end
		end
		if def.drag_target then
			local target = elems[def.drag_target--[[@as string]]]
			if not target then
				error("Drag target not found: "..def.drag_target)
			end
			element.drag_target = target
		end

		if def.children then
			for _, child in pairs(def.children) do
				buildprocessed(element, child, elems)
			end
		end

	elseif def.tab and def.content then
		local tab = buildprocessed(parent, def.tab, elems)
		element = buildprocessed(parent, def.content, elems)
		parent.add_tab(tab, element)

	else
		error("Invalid GUI element definition:"..serpent.block(def))
	end
	return element
end
builder.buildprocessed = buildprocessed

return builder