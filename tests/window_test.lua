package.path = "./?.lua;./?/init.lua;" .. package.path
-- A native harness may preload WezTerm; standalone Lua uses the narrow stub.
local native_wezterm = package.loaded.wezterm
local palette = {
	background = "#24283b",
	foreground = "#c0caf5",
	tab_bar = { background = "#1f2335", inactive_tab = { fg_color = "#a9b1d6" } },
}
package.loaded.wezterm = {
	action = {},
	font = function(spec) return spec end,
	log_info = function() end,
	add_to_config_reload_watch_list = native_wezterm and native_wezterm.add_to_config_reload_watch_list,
}
local lookups = 0
package.loaded.wezmacs = {
	config = { term_mod = "LEADER", gui_mod = "SUPER", alt_mod = "ALT" },
	color_scheme = function()
		lookups = lookups + 1
		return palette
	end,
}
local window = require("wezmacs.modules.window")
local opts = window.opts()
assert(opts.colors == nil, "native palettes must not become recursively merged window options")
assert(lookups == 0, "option discovery must not resolve a palette")
palette = { background = "#010203", foreground = "#fefefe", tab_bar = { background = "#040506" } }
local config = {}
window.setup(config, opts)
assert(config.colors == palette, "setup must resolve the current palette itself")
assert(lookups == 1, "setup must resolve the palette once for colors and frame")
assert(config.window_frame.active_titlebar_bg == "#040506", "fancy frame must match tab bar, not terminal background")
assert(config.window_frame.inactive_titlebar_bg == "#040506")
assert(config.window_frame.active_titlebar_fg == "#fefefe")
assert(config.window_frame.inactive_titlebar_fg == "#fefefe", "missing inactive tab text falls back to foreground")
assert(config.window_padding.left == 16 and config.window_padding.bottom == 16)
local frame = {
	active_titlebar_bg = "#111111",
	inactive_titlebar_bg = "#222222",
	active_titlebar_fg = "#eeeeee",
	inactive_titlebar_fg = "#dddddd",
	font = { family = "Existing UI" },
	font_size = 17,
	border_left_width = "2px",
	border_left_color = "#333333",
}
local existing = { window_frame = {} }
for field, value in pairs(frame) do
	existing.window_frame[field] = value
end
window.setup(existing, opts)
for field, value in pairs(frame) do
	assert(existing.window_frame[field] == value, "preserve explicit frame field: " .. field)
end
palette.tab_bar.inactive_tab = { fg_color = "#a9b1d6" }
local inactive = {}
window.setup(inactive, opts)
assert(inactive.window_frame.inactive_titlebar_fg == "#a9b1d6")
print("PASS window applies resolved colors and coherent frame without replacing overrides")

assert(config.window_background_opacity == 1, "opaque window is an explicit readability default")
assert(config.text_background_opacity == 1)
assert(config.inactive_pane_hsb.brightness == 0.9, "inactive panes must remain readable")
assert(config.inactive_pane_hsb.saturation == 1)
assert(config.adjust_window_size_when_changing_font_size == false, "font changes must preserve the window layout")
assert(config.window_decorations == "RESIZE" and config.window_close_confirmation == "NeverPrompt")
opts.window_background_opacity = 0.95
opts.text_background_opacity = 0.85
opts.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }
opts.adjust_window_size_when_changing_font_size = true
opts.padding, opts.decorations, opts.close_confirmation = 8, "TITLE|RESIZE", "AlwaysPrompt"
opts.font, opts.font_size = "Test UI", 18
window.setup(config, opts)
assert(config.window_background_opacity == 0.95)
assert(config.text_background_opacity == 0.85)
assert(config.inactive_pane_hsb.brightness == 0.7)
assert(config.inactive_pane_hsb.saturation == 0.8)
assert(config.window_decorations == "TITLE|RESIZE" and config.window_close_confirmation == "AlwaysPrompt")
for _, side in ipairs({ "left", "right", "top", "bottom" }) do
	assert(config.window_padding[side] == 8)
end
assert(config.adjust_window_size_when_changing_font_size == true)
assert(config.window_frame.font.family == "Test UI")
assert(config.window_frame.font_size == 18)
assert(config.command_palette_font_size == 18 and config.char_select_font_size == 18)
print("PASS window readability and sizing defaults remain configurable")

-- Exercise the real loader's built-in-then-user setup contract. With native
-- WezTerm preloaded this also validates actual ColorSpec union conversion.
local wezterm = native_wezterm or package.loaded.wezterm
package.loaded.wezterm = wezterm
package.loaded["wezmacs.modules.window"] = nil
local theme = require("wezmacs.theme")
package.loaded.wezmacs.color_scheme = function()
	return theme.resolve(native_wezterm or {
		color = { get_builtin_schemes = function() return { ["tokyonight-storm"] = palette } end },
	}, "tokyonight-storm")
end
local fields = {
	"quick_select_match_bg",
	"quick_select_match_fg",
	"quick_select_label_bg",
	"quick_select_label_fg",
	"copy_mode_active_highlight_bg",
	"copy_mode_active_highlight_fg",
	"copy_mode_inactive_highlight_bg",
	"copy_mode_inactive_highlight_fg",
}
local callback_ran = false
local module, err = require("wezmacs.module")("unused").load({
	"window",
	opts = { font = "Menlo", font_size = 18 },
	setup = function(target, resolved)
		assert(resolved.colors == nil, "the loader must not introduce a colors default")
		assert(resolved.font == "Menlo" and resolved.font_size == 18)
		local colors = target.colors
		for _, field in ipairs(fields) do
			assert(colors[field].Color ~= nil, "built-in setup must apply the default Color first: " .. field)
			colors[field] = { AnsiColor = "Green" }
		end
		-- Reassignment explicitly requests strict native validation after editing.
		target.colors = colors
		callback_ran = true
	end,
})
assert(module, err)
assert(module.opts.colors == nil)
local overridden = native_wezterm and native_wezterm.config_builder() or {}
if native_wezterm then
	overridden:set_strict_mode(true)
end
module.setup(overridden, module.opts)
assert(callback_ran, "user setup must run after built-in setup")
for _, field in ipairs(fields) do
	local color = overridden.colors[field]
	assert(color.AnsiColor == "Green" and color.Color == nil, "ColorSpec must be replaced atomically: " .. field)
	local count = 0
	for _ in pairs(color) do
		count = count + 1
	end
	assert(count == 1, "native ColorSpec must have exactly one variant: " .. field)
end
assert(overridden.window_frame.font_size == 18)
assert(overridden.command_palette_font_size == 18 and overridden.char_select_font_size == 18)
if native_wezterm then
	local validated = native_wezterm.config_builder()
	validated:set_strict_mode(true)
	for field, value in pairs(overridden) do
		validated[field] = value
	end
	validated.keys = {
		{
			key = "F24",
			mods = "CTRL|SHIFT|ALT|SUPER",
			action = native_wezterm.action.SendString("__WINDOW_NATIVE_VALIDATED__"),
		},
	}
	print("PASS native window setup Color-to-AnsiColor replacements: 8 fields")
	return validated
end
print("PASS window loader setup Color-to-AnsiColor replacements: 8 fields")
