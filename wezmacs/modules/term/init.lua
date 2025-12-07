--[[
  Module: term
  Description: Core WezTerm settings and global event handlers
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
	name = "term",
	description = "Core WezTerm settings and global event handlers",

	opts = function()
		return {
			default_prog = nil, -- nil = use WezTerm default
			scrollback_lines = 5000,
			enable_scroll_bar = true,
			default_cursor_style = "BlinkingBlock",
			cursor_blink_rate = 650,
			cursor_blink_ease_in = "EaseOut",
			cursor_blink_ease_out = "EaseOut",
			enable_kitty_keyboard = true,
			enable_kitty_graphics = true,
			disable_close_warning = true,

			-- Keybindings
			term_mod = wezmacs.config.term_mod,
			gui_mod = wezmacs.config.gui_mod,
			ctrl_mod = wezmacs.config.ctrl_mod,

			-- Font
			font = nil,
			font_size = nil,
			font_rules = {
				{ intensity = "Normal", italic = false, weight = "Medium" },
				{ intensity = "Bold", italic = false, weight = "ExtraBold" },
				{ intensity = "Half", italic = false, weight = "Thin" },
				{ intensity = "Normal", italic = true, weight = "Regular", style = "Italic" },
				{ intensity = "Bold", italic = true, weight = "Bold", style = "Italic" },
				{ intensity = "Half", italic = true, weight = "Thin", style = "Italic" },
			},
			ligatures = {
				enabled = false,
				harfbuzz_features = {
					"ss01",
					"ss02",
					"ss03",
					"ss04",
					"ss05",
					"ss06",
					"ss07",
					"ss08",
					"calt",
					"liga",
					"dlig",
				},
			},
		}
	end,

	keys = function(opts)
		return {
			-- Font Size
			{ key = "+", mods = opts.gui_mod, action = act.IncreaseFontSize, desc = "zoom-in" },
			{ key = "-", mods = opts.gui_mod, action = act.DecreaseFontSize, desc = "zoom-out" },
			{ key = "0", mods = opts.gui_mod, action = act.ResetFontSize, desc = "zoom-reset" },
			{ key = "+", mods = opts.ctrl_mod, action = act.IncreaseFontSize, desc = "zoom-in" },
			{ key = "-", mods = opts.ctrl_mod, action = act.DecreaseFontSize, desc = "zoom-out" },
			{ key = "0", mods = opts.ctrl_mod, action = act.ResetFontSize, desc = "zoom-reset" },

			-- Clipboard
			{ key = "c", mods = opts.term_mod, action = act.CopyTo("Clipboard"), desc = "copy" },
			{ key = "v", mods = opts.term_mod, action = act.PasteFrom("Clipboard"), desc = "paste" },
			{ key = "c", mods = opts.gui_mod, action = act.CopyTo("Clipboard"), desc = "copy" },
			{ key = "v", mods = opts.gui_mod, action = act.PasteFrom("Clipboard"), desc = "paste" },
			{ key = "Copy", action = act.CopyTo("Clipboard"), desc = "copy" },
			{ key = "Paste", action = act.PasteFrom("Clipboard"), desc = "paste" },
			{ key = "Insert", mods = opts.ctrl_mod, action = act.CopyTo("PrimarySelection"), desc = "copy-primary" },
			{ key = "Insert", mods = "SHIFT", action = act.PasteFrom("PrimarySelection"), desc = "paste-primary" },
			{ key = "Y", mods = "LEADER", action = act.CopyTo("PrimarySelection"), desc = "copy-primary" },
			{ key = "P", mods = "LEADER", action = act.PasteFrom("PrimarySelection"), desc = "paste-primary" },

			-- Scrollback
			{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1), desc = "page-up" },
			{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1), desc = "page-down" },
			{ key = "k", mods = opts.term_mod, action = act.ClearScrollback("ScrollbackOnly"), desc = "clear" },
			{ key = "k", mods = opts.gui_mod, action = act.ClearScrollback("ScrollbackOnly"), desc = "clear" },
			{ key = "x", mods = opts.term_mod, action = act.ActivateCopyMode, desc = "copy-mode" },
			{ key = "f", mods = opts.term_mod, action = act.Search({ CaseInSensitiveString = "" }), desc = "search" },
			{ key = "f", mods = opts.gui_mod, action = act.Search({ CaseInSensitiveString = "" }), desc = "search" },
			{ key = "/", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }), desc = "search" },
			{ key = "Space", mods = opts.term_mod, action = act.QuickSelect, desc = "select" },

			{
				key = "o",
				mods = "LEADER",
				action = act.QuickSelectArgs({
					label = "open url/path/hash",
					patterns = {
						"https?://\\S+",
						"git@[\\w.-]+:[\\w./-]+",
						"file://\\S+",
						"[~./]\\S+/\\S+",
						"/[a-zA-Z0-9_/-]+",
						"\\b[a-f0-9]{7,40}\\b",
						"\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b",
						"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
					},
				}),
				desc = "open-link",
			},
		}
	end,

	setup = function(config, opts)
		config.enable_kitty_keyboard = opts.enable_kitty_keyboard
		config.enable_kitty_graphics = opts.enable_kitty_graphics

		-- Cursor configuration
		config.default_cursor_style = opts.default_cursor_style
		config.cursor_blink_rate = opts.cursor_blink_rate
		config.cursor_blink_ease_in = opts.cursor_blink_ease_in
		config.cursor_blink_ease_out = opts.cursor_blink_ease_out

		-- Scrolling behavior
		config.scrollback_lines = opts.scrollback_lines
		config.enable_scroll_bar = opts.enable_scroll_bar

		-- Shell and workspace defaults
		if opts.default_prog then
			config.default_prog = opts.default_prog
		end

		-- Disable warning for stateful tabs
		if opts.disable_close_warning then
			wezterm.on("mux-is-process-stateful", function(_)
				return false
			end)
		end

		-- Color scheme configuration
		local color_scheme = wezmacs.color_scheme()
		if color_scheme then
			config.colors = color_scheme
		end

		-- Font configuration
		if opts.font then
			config.font = wezterm.font_with_fallback({
				{ family = opts.font, weight = "Medium" },
			})
			config.warn_about_missing_glyphs = false
		end

		if opts.font_size then
			config.font_size = opts.font_size
		end

		-- Apply ligatures only if ligatures feature is enabled
		if opts.ligatures and opts.ligatures.enabled then
			config.harfbuzz_features = opts.ligatures.harfbuzz_features
		end

		-- Font rules for different text styles
		if opts.font and opts.font_rules and type(opts.font_rules) == "table" and #opts.font_rules > 0 then
			config.font_rules = {}
			for _, rule_template in ipairs(opts.font_rules) do
				local rule = {
					intensity = rule_template.intensity,
					italic = rule_template.italic,
					font = wezterm.font_with_fallback({
						{
							family = opts.font,
							weight = rule_template.weight,
							style = rule_template.style,
						},
					}),
				}
				table.insert(config.font_rules, rule)
			end
		end
	end,
}
