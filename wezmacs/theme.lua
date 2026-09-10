-- Palette-derived UI defaults. Never modify the native/plugin source palette.
local M = {}

function M.copy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in pairs(value) do
		copy[key] = M.copy(child)
	end
	return copy
end

local function fill_missing(target, defaults)
	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = M.copy(value)
		end
	end
	return target
end

function M.resolve(wezterm, name)
	local source
	if name == "Rose Pine" then
		source = wezterm.plugin.require("https://github.com/neapsix/wezterm").main.colors()
	else
		source = wezterm.color.get_builtin_schemes()[name]
		if not source then
			error(
				"[WezMacs] Unknown color scheme '"
					.. tostring(name)
					.. "'. Choose a name from wezterm.color.get_builtin_schemes() or the optional 'Rose Pine' plugin.",
				0
			)
		end
	end

	local colors = M.copy(source)
	local ansi = colors.ansi or {}
	local brights = colors.brights or {}
	local tab_bar = colors.tab_bar or {}
	tab_bar.background = tab_bar.background or colors.background
	tab_bar.inactive_tab_edge = tab_bar.inactive_tab_edge or brights[1] or colors.foreground

	local function state(key, background, foreground)
		tab_bar[key] = fill_missing(tab_bar[key] or {}, {
			bg_color = background,
			fg_color = foreground,
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		})
	end

	state("active_tab", ansi[1] or colors.background, colors.foreground)
	state("inactive_tab", colors.background, ansi[8] or colors.foreground)
	-- Storm's native inactive label uses its dim comment color. Use ANSI white
	-- for readability, retaining its background and all other explicit states.
	if name == "tokyonight-storm" then
		tab_bar.inactive_tab.fg_color = ansi[8] or colors.foreground
	end
	state("inactive_tab_hover", tab_bar.inactive_tab.bg_color, ansi[5] or colors.foreground)
	state("new_tab", tab_bar.inactive_tab.bg_color, tab_bar.inactive_tab.fg_color)
	state("new_tab_hover", tab_bar.inactive_tab_hover.bg_color, tab_bar.inactive_tab_hover.fg_color)
	colors.tab_bar = tab_bar

	local accent = ansi[5] or colors.foreground
	local dark = ansi[1] or colors.background
	local compose = ansi[4] or accent
	fill_missing(colors, {
		split = tab_bar.inactive_tab_edge,
		scrollbar_thumb = brights[1] or tab_bar.inactive_tab_edge,
		compose_cursor = compose,
		-- These options take ColorSpec variants, not bare color strings.
		copy_mode_active_highlight_bg = { Color = accent },
		copy_mode_active_highlight_fg = { Color = dark },
		copy_mode_inactive_highlight_bg = { Color = colors.selection_bg or ansi[8] or colors.foreground },
		copy_mode_inactive_highlight_fg = { Color = colors.selection_fg or colors.background },
		quick_select_label_bg = { Color = compose },
		quick_select_label_fg = { Color = dark },
		quick_select_match_bg = { Color = accent },
		quick_select_match_fg = { Color = dark },
	})
	return colors
end

return M
