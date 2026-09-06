package.path = "./?.lua;./?/init.lua;" .. package.path
local callback
package.loaded.wezterm = {
	action = setmetatable({}, {
		__index = function(_, name)
			return function(...) return { name, ... } end
		end,
	}),
	action_callback = function(fn) return fn end,
	plugin = {
		require = function()
			return {
				switch_workspace = function() return {} end,
				switch_to_prev_workspace = function() return {} end,
			}
		end,
	},
}
package.loaded.wezmacs = { config = { term_mod = "CTRL|SHIFT", gui_mod = "SUPER", ctrl_mod = "CTRL" } }
local mod = require("wezmacs.modules.mux")
for _, key in ipairs(mod.keys(mod.opts)) do
	if key.key == "W" and key.mods == "LEADER" then
		callback = key.action
	end
end
local focused = false
local pane = {
	move_to_new_window = function()
		return {}, {
			gui_window = function()
				return { focus = function() focused = true end }
			end,
		}
	end,
}
assert(callback, "move-to-window action missing")
callback({}, pane)
assert(focused, "must focus the GUI window, not call nonexistent MuxWindow.activate")
print("PASS move-pane action focuses the GUI window")
