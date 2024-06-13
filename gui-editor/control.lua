local handler = require("event_handler")
handler.add_lib(require("__gui-modules__.gui"))

require("__gui-editor__.interface.main")


local def6 = {
	{
		type = "test",
		name = "Final element 1",
	},
	{
		type = "test",
		name = "Final element 2",
	},
	{
		type = "test",
		name = "Final element 3",
	},
	{
		type = "test",
		name = "Final element 4",
	},
	{
		type = "test",
		name = "Final element 5",
	},
}
local def5 = {
	type = "test",
	children = def6
}
local def4 = {
	type = "test",
	children = {
		def5,
		def5,
		def5,
		def5,
		def5,
	}
}
local def3 = {
	type = "test",
	children = {
		def4,
		def4,
		def4,
		def4,
		def4,
	}
}
local def2 = {
	type = "test",
	children = {
		def3,
		def3,
		def3,
		def3,
		def3,
	}
}
local def = {
	type = "test",
	name = "root-element",
	children = {
		def2,
		def2,
		def2,
		def2,
		def2,
	}
}


local function recursive_while(def, elems)
  -- If a single def was passed, wrap it in an array
  if def.type or (def.tab and def.content) then
    def = { def }
	end
	elems = elems or {}

  local first
  for i = 1, #def do
    local def = def[i]
    if def.type then
			local name = def.name
			print(i, name)
			if name then
				elems[name] = def
			end
			local children = def.children
			def.children = nil
			if children then
				recursive_while(children, elems)
			end
			def.children = children
		elseif def.tab and def.content then
			recursive_while(def.tab, elems)
			recursive_while(def.content, elems)
		end
	end
end

local every_child = require("__gui-modules__.children-iterator")

local function iterator(def, elems)
	elems = elems or {}
	for parent_elem, index, child in every_child(def) do
		local name = child.name
		print(index, name)
		if name then
			elems[name] = def
		end
	end
end
local test = {}
test.events = {
	[defines.events.on_lua_shortcut] = function (event)
		if event.prototype_name == "visual-editor2" then
			recursive_while(def)
		elseif event.prototype_name == "visual-editor" then
			iterator(def)
		end
	end
}
handler.add_lib(test)