-- Offline embedded-runtime regression: real ColorSpec conversion and tab states.
local wezterm = require("wezterm")
local ok, config = xpcall(function()
	local root = assert(os.getenv("WEZMACS_SMOKE_ROOT"))
	package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
	assert(package.loaded.wezterm == wezterm, "native require must preload wezterm")
	local window_config = dofile(root .. "/tests/window_test.lua")
	assert(window_config.colors.quick_select_match_bg.AnsiColor == "Green")
	local colors = require("wezmacs.theme").resolve(wezterm, "tokyonight-storm")
	assert(colors.tab_bar.background == colors.background, "Storm strip must match the terminal background")
	for _, name in ipairs({ "active_tab", "inactive_tab", "inactive_tab_hover", "new_tab", "new_tab_hover" }) do
		assert(colors.tab_bar[name].bg_color == colors.tab_bar.background, name .. " must match the dark strip")
	end
	assert(colors.tab_bar.active_tab.fg_color == colors.ansi[5])
	assert(colors.tab_bar.inactive_tab.fg_color == colors.ansi[8])
	assert(colors.tab_bar.inactive_tab_hover.fg_color == colors.foreground)
	assert(colors.tab_bar.new_tab_hover.fg_color == colors.foreground)
	for _, fancy in ipairs({ true, false }) do
		local validated = wezterm.config_builder()
		---@cast validated WezmacsConfigBuilder
		validated:set_strict_mode(true)
		validated.colors = colors
		validated.use_fancy_tab_bar = fancy
	end
	local validated = wezterm.config_builder()
	---@cast validated WezmacsConfigBuilder
	validated:set_strict_mode(true)
	for field, value in pairs(window_config) do
		validated[field] = value
	end
	validated.keys = {
		{
			key = "F24",
			mods = "CTRL|SHIFT|ALT|SUPER",
			action = wezterm.action.SendString("__WEZMACS_REGRESSION_VALIDATED__"),
		},
	}
	print("PASS native appearance styling and ColorSpec overrides")
	return validated
end, tostring)
if not ok then
	io.stderr:write(tostring(config), "\n")
	os.exit(1)
end
return config
