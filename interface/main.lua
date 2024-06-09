---@type flib_gui
local flib_gui = require("__flib__.gui-lite")
local modules = require("__visual-gui-editor__.interface.library")
local main = {}



---Creates the interface for the player
---@param player LuaPlayer
function main.create(player)
	local elems, root = flib_gui.add(player.gui.screen,
		modules.frame_with_buttons{
			name = "root-element",
			title = "TEST",
			children = {
				type = "label",
				caption = "This is to test that it works :P"
			}
		}
	)
end
return main