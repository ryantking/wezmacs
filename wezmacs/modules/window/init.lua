--[[
  Module: window
  Description: Window decorations, padding, scrolling, and cursor behavior
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
	name = "window",
	description = "Window behavior, padding, and cursor settings",

	opts = function()
		return {
			padding = 16,
			decorations = "RESIZE",
			close_confirmation = "NeverPrompt",

			-- Keybindings
			term_mod = wezmacs.config.term_mod,
			gui_mod = wezmacs.config.gui_mod,
			alt_mod = wezmacs.config.alt_mod,
		}
	end,

	keys = function(opts)
		return {
			{ key = "n", mods = opts.term_mod, action = act.SpawnWindow, desc = "new-window" },
			{ key = "n", mods = opts.gui_mod, action = act.SpawnWindow, desc = "new-window" },
			{ key = "Enter", mods = opts.alt_mod, action = act.ToggleFullScreen, desc = "fullscreen" },
			{ key = "m", mods = opts.gui_mod, action = act.Hide, desc = "minimize" },
		}
	end,

	setup = function(config, opts)
		-- Window decorations and behavior
		config.window_decorations = opts.decorations
		config.window_close_confirmation = opts.close_confirmation

		-- Window padding (equal on all sides)
		local p = opts.padding
		config.window_padding = {
			left = p,
			right = p,
			top = p,
			bottom = p,
		}
	end,
}
