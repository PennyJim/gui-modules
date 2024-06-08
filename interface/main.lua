---@type flib_gui
local gui = require("__flib__.gui-lite")
local gui_lib = require("__visual-gui-editor__.interface.library")

local main = {}



---Creates the interface for the player
---@param player LuaPlayer
---@return LuaGuiElement
function main.create(player)
	local elems, root = gui.add(player.gui.screen,
		gui_lib.frame_with_exit("visual-editor", "TEST", "close_frame", {
			type = "label",
			caption = "This is to test that it works :P"
	}))
	return root
end


return main