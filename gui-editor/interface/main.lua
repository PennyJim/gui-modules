---@type flib_gui
local flib_gui = require("__flib__.gui-lite")
local modules = require("__visual-gui-editor__.interface.library")
local main = {}
main.handlers = {}

---@class WindowState
---@field root LuaGuiElement the root element
---@field elems table<string,LuaGuiElement> the named elements
---@field player LuaPlayer the owner of the window
---@field pinned boolean whether or not this window is pinned

--#region Private Event Handlers

---@param self WindowState
function main.handlers.window_closed(self)
  if self.pinned then
    return
  end
	self.player.opened = nil
end
---@param self WindowState
function main.handlers.hide(self)
  self.root.visible = false
end
---@param self WindowState
function main.handlers.show(self)
	self.root.visible = true
	-- Focus something if it should be focused by default
  if not self.pinned then
    self.player.opened = self.root
  end
end
---@param self WindowState
---@return boolean
function main.handlers.toggle(self)
	if self.root.visible then
		main.handlers.hide(self)
	else
		main.handlers.show(self)
	end
	return self.root.visible
end
--#endregion


---Creates the interface for the player
---@param player LuaPlayer
---@return WindowState
function main.create(player)
	local elems, root = flib_gui.add(player.gui.screen,
		modules.frame_with_buttons{
			name = "root-element",
			title = "TEST",
			window_closed_handler = main.handlers.window_closed,
			close_name = "close",
			close_handler = main.handlers.hide,
			children = {
				type = "label",
				caption = "This is to test that it works :P"
			}
		}
	)
	---@type WindowState
	local self = {
		root = root,
		elems = elems,
		player = player,
		-- Module state variables
		pinned = false,
		-- User state varaibles
	}
	global.main[player.index] = self
	return self
end

-- Maybe wrap this with a function for the user to add their own handlers?
-- Might actually *need* to do that
flib_gui.add_handlers(main.handlers, function (e, handler)
  local self = global.main[e.player_index]
  if not self then return end

	if self.root.valid then
		handler(self, e)
	else
		global.main[e.player_index] = nil -- Delete the entry of invalid guis
	end
end)
flib_gui.handle_events()

--#region Public Event Handlers

---Initialization
function main.init()
	global.main = global.main or {}
end
---Handles the events of new players
---@param EventData EventData.on_player_created
function main.created_player_handler(EventData)
	local player = game.get_player(EventData.player_index)
	if not player then return end -- ??

	main.create(player)
end
---Opens the element of the player that this event sourced from.
---Will create a new one if one isn't found
---@param EventData EventData.on_lua_shortcut|EventData.CustomInputEvent
---@param player LuaPlayer?
---@return boolean? -- The state of the window, if player existed
function main.toggle_handler(EventData, player)
	player = player or game.get_player(EventData.player_index)
	if not player then return end -- ??

	local self = global.main[player.index]
	if not self or not self.root.valid then
		self = main.create(player)
	end

	return main.handlers.toggle(self)
end
---Returns a handler for the given shortcut name
---@param shortcut string
---@return fun(e:EventData.on_lua_shortcut)
function main.shortcut_handler(shortcut)
	if not shortcut then
		error({"library-errors.unknown-shortcut"}, 2)
	end
	---Handles the shortcut event
	---@param EventData EventData.on_lua_shortcut
	return function(EventData)
		if EventData.prototype_name == shortcut then
			local player = game.get_player(EventData.player_index)
			if not player then return end -- ??
			local new_state = main.toggle_handler(EventData, player) --[[@as boolean]]
			player.set_shortcut_toggled(EventData.prototype_name, new_state)
		end
	end
end
-- TODO: add a configuration changed handler that tracks what version of of UI it is
-- If the version is different, just kill and rebuild the menus
--#endregion
return main