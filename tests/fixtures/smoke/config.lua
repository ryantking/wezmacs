-- Loaded only by the native smoke wrapper, never by the user's terminal config.
local wezterm = require("wezterm")
assert(_VERSION == "Lua 5.4", "WezTerm's embedded runtime must match the test target")
assert(type(wezterm.color.get_builtin_schemes) == "function")
assert(type(wezterm.nerdfonts.cod_globe) == "string")
assert(type(wezterm.nerdfonts.md_arrow_down_box) == "string")
return { color_scheme = "Tokyo Night", term_mod = "LEADER" }
