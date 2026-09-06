-- Test-only harness: catch load errors and validate post-assignment mutations.
local wezterm = require("wezterm")
local ok, config = xpcall(function()
	local root = assert(os.getenv("WEZMACS_SMOKE_ROOT"), "WEZMACS_SMOKE_ROOT is required")
	package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
	local loaded = dofile(root .. "/wezterm.lua")
	local validated = wezterm.config_builder()
	---@cast validated WezmacsConfigBuilder
	validated:set_strict_mode(true)
	for field, value in pairs(loaded) do
		validated[field] = value
	end
	local keys = validated.keys or {}
	table.insert(keys, {
		key = "F24",
		mods = "CTRL|SHIFT|ALT|SUPER",
		action = wezterm.action.SendString("__WEZMACS_NATIVE_VALIDATED__"),
	})
	validated.keys = keys
	return validated
end, tostring)
if not ok then
	io.stderr:write(tostring(config), "\n")
	os.exit(1)
end
return config
