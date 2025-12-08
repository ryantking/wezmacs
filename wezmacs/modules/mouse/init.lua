--[[
  Module: mouse
  Description: Mouse bindings and behavior (selection, link opening, etc.)
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
	name = "mouse",
	description = "Mouse bindings and behavior",

	opts = function()
		return {
			alternate_buffer_wheel_scroll_speed = 1,
			bypass_mouse_reporting_modifiers = "SHIFT",
			hide_mouse_cursor_when_typing = false,

			-- Keybindings
			term_mod = wezmacs.config.term_mod,
			gui_mod = wezmacs.config.gui_mod,
		}
	end,

	setup = function(config, opts)
		config.alternate_buffer_wheel_scroll_speed = opts.alternate_buffer_wheel_scroll_speed
		config.bypass_mouse_reporting_modifiers = opts.bypass_mouse_reporting_modifiers
		config.hide_mouse_cursor_when_typing = opts.hide_mouse_cursor_when_typing

		config.mouse_bindings = {
			-- Left-click: Copy selection to clipboard
			{
				event = { Up = { streak = 1, button = "Left" } },
				action = act.CompleteSelection("ClipboardAndPrimarySelection"),
			},

			-- TERMMOD+left-click: Open link or extend selection
			{
				event = { Up = { streak = 1, button = "Left" } },
				mods = opts.term_mod,
				action = act.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
			},

			-- GUI+left-click: Open link or extend selection
			{
				event = { Up = { streak = 1, button = "Left" } },
				mods = opts.gui_mod,
				action = act.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
			},

			-- Quadruple-click: Select semantic zone (word/code block)
			{
				event = { Down = { streak = 4, button = "Left" } },
				action = act.SelectTextAtMouseCursor("SemanticZone"),
			},
		}
	end,
}
