package.path = "./?.lua;./?/init.lua;" .. package.path
local scheme = { ansi = { "#000000" }, brights = { "#ffffff" }, foreground = "#eeeeee", background = "#111111" }
local schemes = { Test = scheme }
local lookups = 0
package.loaded.wezterm = {
	color = {
		get_builtin_schemes = function()
			lookups = lookups + 1
			return schemes
		end,
	},
	get_builtin_color_schemes = function() error("deprecated color API used") end,
}
package.loaded["wezmacs.action"] = {}
package.loaded["wezmacs.module"] = function() return {} end
package.loaded["wezmacs.config"] = { load = function() return { color_scheme = "Test" } end }
local framework = require("wezmacs")
local passed = 0
local function test(name, run)
	run()
	passed = passed + 1
	print("ok - " .. name)
end

test("theme uses current native color API", function()
	assert(framework.color_scheme().background == "#111111")
	assert(framework.color_scheme().tab_bar.active_tab.fg_color == "#eeeeee")
end)

test("cached resolution gives each caller independent palette and tab tables", function()
	local first = framework.color_scheme()
	local second = framework.color_scheme()
	assert(first ~= second, "callers share the cached palette")
	assert(scheme.tab_bar == nil, "resolution mutated the native palette")
	first.ansi[1] = "changed"
	first.tab_bar.active_tab.fg_color = "changed"
	assert(first.tab_bar.inactive_tab_hover.fg_color ~= "changed", "tab states share defaults")
	assert(second.ansi[1] == "#000000" and scheme.ansi[1] == "#000000")
	assert(second.tab_bar.active_tab.fg_color == "#eeeeee")
	assert(framework.color_scheme().tab_bar.active_tab.fg_color == "#eeeeee")
	assert(lookups == 1, "same selected scheme was resolved more than once")
end)

test("unknown theme reports the selection and native discovery API, then recovers", function()
	framework.config.color_scheme = "missing-theme"
	local ok, err = pcall(framework.color_scheme)
	assert(not ok)
	assert(tostring(err):find("missing-theme", 1, true), "error omits the unknown theme name")
	assert(tostring(err):find("wezterm.color.get_builtin_schemes()", 1, true), "error omits discovery guidance")
	framework.config.color_scheme = "Test"
	assert(framework.color_scheme().background == scheme.background)
end)

test("partial tab states fill every field while retaining explicit scheme styling", function()
	schemes.Partial = {
		background = "#101010",
		foreground = "#eeeeee",
		ansi = { "#202020", "#cc0000", "#00cc00", "#cccc00", "#0000cc", "#cc00cc", "#00cccc", "#cccccc" },
		brights = { "#555555" },
		tab_bar = {
			background = "#303030",
			inactive_tab_edge = "#404040",
			active_tab = { bg_color = "#505050", intensity = "Bold" },
			inactive_tab = { fg_color = "#606060", italic = true },
			inactive_tab_hover = { underline = "Single" },
			new_tab = { strikethrough = true },
			new_tab_hover = {},
		},
	}
	framework.config.color_scheme = "Partial"
	local result = framework.color_scheme()
	local tabs = result.tab_bar
	for _, name in ipairs({ "active_tab", "inactive_tab", "inactive_tab_hover", "new_tab", "new_tab_hover" }) do
		local state = tabs[name]
		assert(state.bg_color and state.fg_color, name .. " has incomplete colors")
		assert(state.intensity and state.underline, name .. " has incomplete text styling")
		assert(type(state.italic) == "boolean" and type(state.strikethrough) == "boolean")
	end
	assert(tabs.background == "#303030" and tabs.inactive_tab_edge == "#404040")
	assert(tabs.active_tab.bg_color == "#505050" and tabs.active_tab.fg_color == result.foreground)
	assert(tabs.active_tab.intensity == "Bold" and tabs.active_tab.italic == false)
	assert(tabs.inactive_tab.fg_color == "#606060" and tabs.inactive_tab.italic == true)
	assert(tabs.inactive_tab_hover.underline == "Single" and tabs.inactive_tab_hover.fg_color == result.ansi[5])
	assert(tabs.new_tab.strikethrough == true and tabs.new_tab_hover.fg_color == result.ansi[5])
	assert(schemes.Partial.tab_bar.active_tab.fg_color == nil, "partial source state was mutated")
end)

-- Native Tokyo Night Storm palette/state values; absent fields exercise defaults.
local storm = {
	background = "#24283b",
	foreground = "#c0caf5",
	ansi = { [1] = "#1d202f", [4] = "#e0af68", [5] = "#7aa2f7", [8] = "#a9b1d6" },
	brights = { "#545c7e" },
	tab_bar = {
		active_tab = {
			bg_color = "#7aa2f7",
			fg_color = "#1f2335",
			intensity = "Normal",
			italic = false,
			underline = "None",
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#292e42",
			fg_color = "#545c7e",
			intensity = "Normal",
			italic = false,
			underline = "None",
			strikethrough = false,
		},
		inactive_tab_hover = { bg_color = "#292e42", fg_color = "#7aa2f7" },
	},
}
schemes["tokyonight-storm"] = storm

test("Tokyo Night Storm lifts inactive contrast without replacing native active or hover colors", function()
	framework.config.color_scheme = "tokyonight-storm"
	local tabs = framework.color_scheme().tab_bar
	assert(tabs.inactive_tab.fg_color == storm.ansi[8], "inactive tabs still use dim comment text")
	assert(tabs.inactive_tab.bg_color == storm.tab_bar.inactive_tab.bg_color)
	for key, value in pairs(storm.tab_bar.active_tab) do
		assert(tabs.active_tab[key] == value, "native active state changed: " .. key)
	end
	assert(tabs.inactive_tab_hover.fg_color == storm.ansi[5])
	assert(tabs.new_tab.fg_color == storm.ansi[8] and tabs.new_tab_hover.fg_color == storm.ansi[5])
	assert(storm.tab_bar.inactive_tab.fg_color == "#545c7e", "native inactive state mutated")
end)

test("missing interaction colors derive from the selected palette using native color variants", function()
	local result = framework.color_scheme()
	assert(result.split == storm.brights[1], "split color is not palette-derived")
	assert(result.scrollbar_thumb == storm.brights[1], "scrollbar color is not palette-derived")
	assert(result.compose_cursor == storm.ansi[4], "compose cursor is not palette-derived")
	local expected = {
		copy_mode_active_highlight_bg = storm.ansi[5],
		copy_mode_active_highlight_fg = storm.ansi[1],
		copy_mode_inactive_highlight_bg = storm.ansi[8],
		copy_mode_inactive_highlight_fg = storm.background,
		quick_select_label_bg = storm.ansi[4],
		quick_select_label_fg = storm.ansi[1],
		quick_select_match_bg = storm.ansi[5],
		quick_select_match_fg = storm.ansi[1],
	}
	for key, value in pairs(expected) do
		assert(type(result[key]) == "table" and result[key].Color == value, key .. " needs a native Color variant")
		assert(storm[key] == nil, "source was mutated: " .. key)
	end
	result.quick_select_match_bg.Color = "changed"
	assert(result.copy_mode_active_highlight_bg.Color == storm.ansi[5], "interaction colors share tables")
	assert(framework.color_scheme().quick_select_match_bg.Color == storm.ansi[5])
	assert(storm.split == nil and storm.scrollbar_thumb == nil and storm.compose_cursor == nil)
end)

test("explicit terminal and interaction colors survive resolution without nested aliases", function()
	local source = {
		background = "#121212",
		foreground = "#ededed",
		ansi = { "#010101" },
		brights = { "#ababab" },
		cursor_bg = "#123456",
		cursor_fg = "#234567",
		cursor_border = "#345678",
		selection_bg = "#456789",
		selection_fg = "none",
		indexed = { [136] = "#56789a" },
		split = "#6789ab",
		scrollbar_thumb = "#789abc",
		compose_cursor = "#89abcd",
		copy_mode_active_highlight_bg = { AnsiColor = "Green" },
		copy_mode_active_highlight_fg = { Color = "#010101" },
		copy_mode_inactive_highlight_bg = { Color = "#020202" },
		copy_mode_inactive_highlight_fg = { Color = "#030303" },
		quick_select_label_bg = { Color = "#040404" },
		quick_select_label_fg = { Color = "#050505" },
		quick_select_match_bg = { Color = "#060606" },
		quick_select_match_fg = { Color = "#070707" },
	}
	schemes.Explicit = source
	framework.config.color_scheme = "Explicit"
	local result = framework.color_scheme()
	local function unchanged(actual, original)
		for key, value in pairs(original) do
			if type(value) == "table" then
				assert(actual[key] ~= value, "nested source table shared: " .. key)
				unchanged(actual[key], value)
			else
				assert(actual[key] == value, "explicit palette value replaced: " .. key)
			end
		end
	end
	unchanged(result, source)
	result.indexed[136] = "changed"
	assert(framework.color_scheme().indexed[136] == "#56789a" and source.indexed[136] == "#56789a")
end)

test("Rose Pine remains an optional cached plugin with independently owned colors", function()
	local calls = 0
	local native_lookups = lookups
	package.loaded.wezterm.plugin = {
		require = function(url)
			assert(url == "https://github.com/neapsix/wezterm")
			calls = calls + 1
			return { main = { colors = function() return scheme end } }
		end,
	}
	framework.config.color_scheme = "Rose Pine"
	local first = framework.color_scheme()
	first.ansi[1] = "changed"
	assert(framework.color_scheme().ansi[1] == scheme.ansi[1])
	assert(calls == 1 and lookups == native_lookups)
	assert(scheme.tab_bar == nil)
	framework.config.color_scheme = "tokyonight-storm"
	assert(framework.color_scheme().background == storm.background)
	assert(lookups == native_lookups + 1, "changed selection did not invalidate the cache")
end)

test("foreground and background suffice when optional palette arrays are absent", function()
	schemes.Minimal = { background = "#141414", foreground = "#eeeeee" }
	framework.config.color_scheme = "Minimal"
	local result = framework.color_scheme()
	assert(result.tab_bar.inactive_tab.fg_color == result.foreground)
	assert(result.split == result.foreground and result.compose_cursor == result.foreground)
	assert(result.quick_select_match_bg.Color == result.foreground)
	assert(result.ansi == nil and result.brights == nil, "resolution synthesized terminal palette entries")
end)

print("theme_test: " .. passed .. " passed")
