package.path = "./?.lua;./?/init.lua;" .. package.path
local scheme = { ansi = { "#000000" }, brights = { "#ffffff" }, foreground = "#eeeeee", background = "#111111" }
package.loaded.wezterm = {
	color = { get_builtin_schemes = function() return { Test = scheme } end },
	get_builtin_color_schemes = function() error("deprecated color API used") end,
}
package.loaded["wezmacs.action"] = {}
package.loaded["wezmacs.module"] = function() return {} end
package.loaded["wezmacs.config"] = { load = function() return { color_scheme = "Test" } end }
local framework = require("wezmacs")
assert(framework.color_scheme().background == "#111111")
assert(framework.color_scheme().tab_bar.active_tab.fg_color == "#eeeeee")
print("PASS theme uses current native color API")
