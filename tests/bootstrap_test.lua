package.path = "./?.lua;./?/init.lua;" .. package.path
local logs = {}
package.loaded.wezterm = {
	config_dir = ".",
	config_builder = function()
		return { set_strict_mode = function() end }
	end,
	log_info = function(message) table.insert(logs, message) end,
	log_error = function(message) table.insert(logs, message) end,
}
package.loaded.wezmacs = {
	config_dir = "test",
	module = {
		list = function() return { "broken" } end,
		load = function() return nil, "broken: regression error" end,
	},
}
local ok, err = pcall(dofile, "wezterm.lua")
assert(not ok, "bootstrap must reject failed modules instead of announcing success")
assert(tostring(err):find("broken: regression error", 1, true), tostring(err))
for _, log in ipairs(logs) do
	assert(not log:find("loaded successfully", 1, true), "failure reported as success")
end
print("PASS bootstrap rejects failed modules")

local strict = false
package.loaded.wezterm.config_builder = function()
	return { set_strict_mode = function(_, value) strict = value end }
end
package.loaded.wezmacs.module.list = function() return {} end
dofile("wezterm.lua")
assert(strict, "bootstrap must enable native config-builder strict validation")
print("PASS bootstrap enables strict native validation")
