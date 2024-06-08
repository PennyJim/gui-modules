require("__visual-gui-editor__.library.global")
main_gui = require("__visual-gui-editor__.interface.main")


script.on_init(function ()
	init_global()
end)

script.on_event(defines.events.on_player_created, function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then return end -- ??

	main_gui.create(player)
end)