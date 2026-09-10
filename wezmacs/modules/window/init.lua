--[[
  Module: window
  Description: Theme application, window chrome, spacing, and UI fonts
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
	name = "window",
	description = "Theme, window chrome, spacing, and UI fonts",

	opts = function()
		return {
			font = nil,
			font_size = nil,
			padding = 16,
			decorations = "RESIZE",
			close_confirmation = "NeverPrompt",
			window_background_opacity = 1,
			text_background_opacity = 1,
			inactive_pane_hsb = { saturation = 1, brightness = 0.9 },
			adjust_window_size_when_changing_font_size = false,

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
		local colors = wezmacs.color_scheme()
		config.colors = colors
		config.window_decorations = opts.decorations
		config.window_close_confirmation = opts.close_confirmation
		config.window_background_opacity = opts.window_background_opacity
		config.text_background_opacity = opts.text_background_opacity
		config.inactive_pane_hsb = opts.inactive_pane_hsb
		config.adjust_window_size_when_changing_font_size = opts.adjust_window_size_when_changing_font_size

		local window_frame = config.window_frame or {}
		local bar = colors.tab_bar or {}
		local background = bar.background or colors.background
		window_frame.inactive_titlebar_bg = window_frame.inactive_titlebar_bg or background
		window_frame.active_titlebar_bg = window_frame.active_titlebar_bg or background
		window_frame.active_titlebar_fg = window_frame.active_titlebar_fg or colors.foreground
		window_frame.inactive_titlebar_fg = window_frame.inactive_titlebar_fg
			or (bar.inactive_tab and bar.inactive_tab.fg_color)
			or colors.foreground
		config.window_frame = window_frame

		-- Window padding (equal on all sides)
		local p = opts.padding
		config.window_padding = {
			left = p,
			right = p,
			top = p,
			bottom = p,
		}

		-- UI fonts (for UI elements) - only if configured
		if opts.font then
			local ui_font = wezterm.font({ family = opts.font })
			-- Native palettes/selectors inherit this font unless explicitly overridden.
			config.window_frame.font = ui_font
		end

		if opts.font_size then
			config.char_select_font_size = opts.font_size
			config.command_palette_font_size = opts.font_size
			config.window_frame.font_size = opts.font_size
		end
	end,
}
