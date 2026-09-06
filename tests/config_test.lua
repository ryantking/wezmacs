-- Run from the repository root: lua tests/config_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
package.loaded.wezterm = { target_triple = "aarch64-apple-darwin" }
local config = require("wezmacs.config")
local passed = 0

local function test(name, run)
	run()
	passed = passed + 1
	print("ok - " .. name)
end

local function with_file(source, run)
	local path = os.tmpname()
	local file = assert(io.open(path, "w"))
	assert(file:write(source))
	assert(file:close())
	local ok, err = pcall(run, path)
	assert(os.remove(path))
	assert(ok, err)
end

test("missing optional config uses defaults", function()
	local path = os.tmpname()
	assert(os.remove(path))
	local result = config.load(path)
	assert(result.color_scheme == config.defaults.color_scheme)
	assert(config.load().platform == "darwin")
end)

test("malformed existing config raises path and phase errors", function()
	local failures = {}
	for _, case in ipairs({
		{ "return {", "load" },
		{ "error('config exploded')", "execute", "config exploded" },
		{ "return false", "must return a table" },
		{ "return 'bad'", "must return a table" },
		{ "return nil", "must return a table" },
	}) do
		local ok, err = pcall(with_file, case[1], function(path)
			local success, result = pcall(config.load, path)
			assert(not success, "malformed config silently fell back to defaults: " .. case[1])
			assert(tostring(result):find(path, 1, true), "missing path in: " .. tostring(result))
			assert(tostring(result):find(case[2], 1, true), "missing phase in: " .. tostring(result))
			if case[3] then
				assert(tostring(result):find(case[3], 1, true))
			end
		end)
		if not ok then
			failures[#failures + 1] = tostring(err)
		end
	end
	assert(#failures == 0, table.concat(failures, "\n"))
end)

test("config open errors other than missing files are surfaced", function()
	local path = "./wezmacs/config.lua/invalid-child"
	local ok, err = pcall(config.load, path)
	assert(not ok, "non-missing open failure silently fell back to defaults")
	assert(tostring(err):find(path, 1, true) and tostring(err):find("open", 1, true))
end)

test("loaded config owns nested default tables", function()
	---@type table
	local defaults = config.defaults
	defaults.test_nested = { values = { "original" } }
	local result = config.load()
	result.test_nested.values[1] = "changed"
	local unchanged = defaults.test_nested.values[1] == "original"
	defaults.test_nested = nil
	assert(unchanged, "loaded config mutated nested defaults")
end)

test("user settings replace top-level defaults without sharing tables", function()
	---@type table
	local defaults = config.defaults
	defaults.test_nested = { values = { "old", "tail" }, retained = true }
	local user = { color_scheme = "Test", test_nested = { values = { "new" } }, enabled = false }
	package.loaded.config_test_values = user
	local ok, err = pcall(with_file, "return require('config_test_values')", function(path)
		local result = config.load(path)
		assert(result.color_scheme == "Test" and result.enabled == false)
		assert(result.term_mod == defaults.term_mod)
		assert(#result.test_nested.values == 1 and result.test_nested.retained == nil)
		result.test_nested.values[1] = "changed"
		assert(user.test_nested.values[1] == "new", "loaded config mutated user tables")
	end)
	package.loaded.config_test_values = nil
	defaults.test_nested = nil
	assert(ok, err)
end)

print("config_test: " .. passed .. " passed")
