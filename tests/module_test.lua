-- Run from the repository root: lua tests/module_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
package.loaded.wezterm = { log_info = function() end, log_error = function() end }
local loader = require("wezmacs.module")(".")
local passed = 0

-- Fixtures supply module definitions, not replacements for the real loader.
local function fixture(definition)
	package.loaded["wezmacs.modules.loader_test"] = nil
	package.preload["wezmacs.modules.loader_test"] = function() return definition end
end

local function test(name, run)
	run()
	passed = passed + 1
	print("ok - " .. name)
end

test("user dependency callback is preserved and receives merged options", function()
	fixture({ name = "loader_test", opts = { command = "tool" } })
	local mod, err = loader.load({
		"loader_test",
		deps = function(opts) return { opts.command } end,
	})
	assert(mod, err)
	assert(mod.deps[1] == "tool", "user deps were discarded")
end)

test("user-only setup runs with config and merged options", function()
	fixture({ name = "loader_test", opts = { enabled = true } })
	local mod, err = loader.load({
		"loader_test",
		setup = function(config, opts) config.enabled = opts.enabled end,
	})
	assert(mod, err)
	local config = {}
	mod.setup(config, mod.opts)
	assert(config.enabled == true, "user setup was discarded")
end)

test("module setup runs before user setup", function()
	fixture({
		name = "loader_test",
		opts = { suffix = "user" },
		setup = function(config) config.order = "module" end,
	})
	local mod, err = loader.load({
		"loader_test",
		setup = function(config, opts) config.order = config.order .. "," .. opts.suffix end,
	})
	assert(mod, err)
	local config = {}
	local ok, setup_err = pcall(mod.setup, config, mod.opts)
	assert(ok, "composed setup failed: " .. tostring(setup_err))
	assert(config.order == "module,user", "setup order changed")
end)

local function rejects(entry, ...)
	local ok, mod, err = pcall(loader.load, entry)
	assert(ok, "load threw instead of returning an error: " .. tostring(mod))
	assert(mod == nil and type(err) == "string", "expected nil and a contextual error")
	for _, text in ipairs({ ... }) do
		assert(err:find(text, 1, true), "missing '" .. text .. "' in: " .. err)
	end
end

-- Run all related invalid cases so each regression is visible in a RED run.
local function cases(values, run)
	local failures = {}
	for _, value in ipairs(values) do
		local ok, err = pcall(run, value)
		if not ok then
			failures[#failures + 1] = tostring(err)
		end
	end
	assert(#failures == 0, table.concat(failures, "\n"))
end

test("invalid module names return entry errors without requiring modules", function()
	cases(
		{ {}, { 23 }, { false }, { "" }, { "   " }, "", 42, false },
		function(entry) rejects(entry, "entry", "name") end
	)
end)

test("invalid user field types return module and field errors", function()
	fixture({ name = "loader_test" })
	cases({ "opts", "keys", "deps", "setup" }, function(field)
		cases(
			{ false, 7, "bad", field == "setup" and {} or true },
			function(value) rejects({ "loader_test", [field] = value }, "loader_test", "user " .. field, "must be") end
		)
	end)
end)

test("require failures return contextual errors", function()
	package.loaded["wezmacs.modules.loader_test"] = nil
	package.preload["wezmacs.modules.loader_test"] = function() error("fixture require exploded") end
	cases(
		{ { "loader_test_missing_module", "not found" }, { "loader_test", "fixture require exploded" } },
		function(value) rejects(value[1], value[1], "require", value[2]) end
	)
end)

test("required modules must return tables", function()
	cases({ true, false, 12, "bad", function() end }, function(value)
		fixture(value)
		rejects("loader_test", "loader_test", "must return a table")
	end)
end)

test("module name metadata is optional", function()
	fixture({})
	local ok, mod, err = pcall(loader.load, "loader_test")
	assert(ok, "module without name metadata threw: " .. tostring(mod))
	assert(mod, err)
	assert(mod.name == "loader_test")
	mod.setup({}, mod.opts)
end)

test("invalid module field types return module and field errors", function()
	cases({ "opts", "keys", "deps", "setup" }, function(field)
		cases({ false, 7, "bad", field == "setup" and {} or true }, function(value)
			fixture({ [field] = value })
			rejects("loader_test", "loader_test", "module " .. field, "must be")
		end)
	end)
end)

test("module and user callback failures return field context", function()
	cases({ "opts", "keys", "deps" }, function(field)
		cases({ "module", "user" }, function(source)
			local definition = {}
			---@type table
			local entry = { "loader_test" }
			---@type table<string|integer, any>
			local target = source == "module" and definition or entry
			target[field] = function() error("callback exploded") end
			fixture(definition)
			rejects(entry, "loader_test", source .. " " .. field, "callback exploded")
		end)
	end)
end)

test("field callbacks must return tables", function()
	cases({ "opts", "keys", "deps" }, function(field)
		cases({ "module", "user" }, function(source)
			cases({ {}, { false }, { 3 }, { "bad" } }, function(result)
				local definition = {}
				---@type table
				local entry = { "loader_test" }
				---@type table<string|integer, any>
				local target = source == "module" and definition or entry
				target[field] = function() return result[1] end
				fixture(definition)
				rejects(entry, "loader_test", source .. " " .. field, "must return a table")
			end)
		end)
	end)
end)

test("loaded fields do not alias defaults or user tables", function()
	cases({ "opts", "keys", "deps" }, function(field)
		local defaults = { nested = { value = "default" } }
		local overrides = { custom = { value = "user" } }
		fixture({ [field] = defaults })
		local mod = assert(loader.load({ "loader_test", [field] = overrides }))
		mod[field].nested.value = "changed"
		mod[field].custom.value = "changed"
		assert(defaults.nested.value == "default", field .. " mutated module defaults")
		assert(overrides.custom.value == "user", field .. " mutated user input")
		local again = assert(loader.load("loader_test"))
		again[field].nested.value = "changed again"
		assert(defaults.nested.value == "default", field .. " without overrides aliases defaults")
	end)
end)

test("option and dependency sequences replace instead of merging indices", function()
	fixture({
		opts = { branches = { "main", "master", "origin/main" }, nested = { enabled = true, width = 2 } },
		deps = { "old", "extra" },
	})
	cases({ { "new" }, {} }, function(sequence)
		local mod =
			assert(loader.load({ "loader_test", opts = { branches = sequence, nested = { width = 4 } }, deps = sequence }))
		assert(#mod.opts.branches == #sequence, "option sequence retained default tail")
		assert(#mod.deps == #sequence, "dependency sequence retained default tail")
		assert(mod.opts.branches[1] == sequence[1] and mod.deps[1] == sequence[1])
		assert(mod.opts.nested.enabled == true and mod.opts.nested.width == 4, "maps should still merge recursively")
	end)
end)

test("omitted fields preserve default sequences", function()
	fixture({ opts = { "option" }, keys = { { key = "a", action = "ActivateCopyMode" } }, deps = { "tool" } })
	cases({ "loader_test", { "loader_test" } }, function(entry)
		local mod = assert(loader.load(entry))
		assert(mod.opts[1] == "option", "omitted opts cleared defaults")
		assert(mod.keys[1] and mod.keys[1].key == "a", "omitted keys cleared defaults")
		assert(mod.deps[1] == "tool", "omitted deps cleared defaults")
	end)
end)

test("named keybinding overrides replace action variants atomically", function()
	fixture({ keys = { LEADER = { c = { action = { SendString = "old" }, desc = "old description" } } } })
	local mod = assert(loader.load({ "loader_test", keys = { LEADER = { c = { action = { CopyTo = "Clipboard" } } } } }))
	local binding = mod.keys.LEADER.c
	assert(binding.action.SendString == nil, "action variants were recursively merged")
	assert(binding.action.CopyTo == "Clipboard")
	assert(binding.desc == nil, "replaced binding retained old metadata")
end)

test("mixed key maps merge named groups but replace numeric binding lists", function()
	fixture({
		keys = {
			{ key = "a", action = "ActivateCopyMode" },
			{ key = "b", action = "PopKeyTable" },
			LEADER = { c = { action = "ActivateCopyMode" } },
		},
	})
	cases({
		function()
			local mod = assert(loader.load({ "loader_test", keys = { LEADER = { d = { action = "PopKeyTable" } } } }))
			assert(#mod.keys == 2, "named override discarded numeric defaults")
			assert(mod.keys.LEADER.c and mod.keys.LEADER.d)
		end,
		function()
			local mod = assert(loader.load({ "loader_test", keys = { { key = "z", action = "PopKeyTable" } } }))
			assert(#mod.keys == 1 and mod.keys[1].key == "z")
			assert(mod.keys.LEADER, "list replacement discarded named defaults")
		end,
		function()
			fixture({ keys = { LEADER = { c = { action = "ActivateCopyMode" } } } })
			local mod = assert(loader.load({ "loader_test", keys = { LEADER = {} } }))
			assert(next(mod.keys.LEADER) == nil, "empty key group did not clear defaults")
		end,
	}, function(run) run() end)
end)

local function with_modules(source, run)
	local directory = os.tmpname()
	assert(os.remove(directory))
	assert(os.execute('mkdir "' .. directory .. '"'))
	local path = directory .. "/modules.lua"
	if source then
		local file = assert(io.open(path, "w"))
		assert(file:write(source))
		assert(file:close())
	end
	local ok, err = pcall(run, require("wezmacs.module")(directory), path)
	if source then
		assert(os.remove(path))
	end
	assert(os.remove(directory))
	assert(ok, err)
end

test("missing or malformed required modules file raises contextual errors", function()
	cases({
		{ false, "open" },
		{ "return {", "load" },
		{ "error('list exploded')", "execute" },
		{ "return false", "must return a table" },
	}, function(value)
		with_modules(value[1], function(api, path)
			local ok, err = pcall(api.list)
			assert(not ok, "broken modules file silently became an empty list")
			assert(tostring(err):find(path, 1, true), "missing path in: " .. tostring(err))
			assert(tostring(err):find(value[2], 1, true), "missing phase in: " .. tostring(err))
		end)
	end)
end)

test("module lists must be dense sequences", function()
	cases({
		"return { named = 'loader_test' }",
		"return { [1] = 'loader_test', [3] = 'loader_test' }",
		"return { [0] = 'loader_test' }",
		"return { [1.5] = 'loader_test' }",
	}, function(source)
		with_modules(source, function(api, path)
			local ok, err = pcall(api.list)
			assert(not ok, "non-sequence modules table was accepted")
			assert(tostring(err):find(path, 1, true) and tostring(err):find("dense sequence", 1, true))
		end)
	end)
end)

test("valid module lists retain order and allow explicit empty lists", function()
	with_modules("return { 'first', { 'second', opts = { enabled = true } } }", function(api)
		local entries = api.list()
		assert(#entries == 2 and entries[1] == "first" and entries[2][1] == "second")
		assert(entries[2].opts.enabled == true)
	end)
	with_modules("return {}", function(api) assert(next(api.list()) == nil) end)
end)

print("module_test: " .. passed .. " passed")
