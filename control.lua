main_gui = require("__visual-gui-editor__.interface.main")


script.on_init(function ()
	main_gui.init()
end)

script.on_event("visual-editor", main_gui.toggle_handler)
script.on_event(defines.events.on_lua_shortcut, main_gui.shortcut_handler("visual-editor"))

script.on_event(defines.events.on_player_created, main_gui.created_player_handler)