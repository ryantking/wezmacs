-- Run from the repository root: lua tests/generator_test.lua
-- Uses the current Lua executable (or $LUA) and isolated temporary directories.
local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end

local pwd = assert(io.popen("pwd"))
local cwd = assert(pwd:read("*l"))
assert(pwd:close())
local test_path = arg[0]:sub(1, 1) == "/" and arg[0] or cwd .. "/" .. arg[0]
local repo = assert(test_path:match("^(.*)/tests/[^/]+$"))
local generator = repo .. "/scripts/generate-config.lua"
local lua = os.getenv("LUA") or arg[-1] or "lua"
local passed, failed = 0, 0

local function mkdir(path) assert(os.execute("mkdir -p " .. quote(path))) end

local function write(path, content)
	local file = assert(io.open(path, "w"))
	assert(file:write(content))
	assert(file:close())
end

local function read(path)
	local file = assert(io.open(path, "r"))
	local content = assert(file:read("*a"))
	assert(file:close())
	return content
end

local function absent(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		error("unexpected file: " .. path)
	end
end

local function run(root, output, env, script)
	env = env or {}
	local command = "cd " .. quote(root) .. " && env -u HOME -u XDG_CONFIG_HOME -u WEZMACSDIR"
	for _, name in ipairs({ "HOME", "XDG_CONFIG_HOME", "WEZMACSDIR" }) do
		local value = env[name]
		if value == nil then
			value = root .. "/" .. name
		end
		if value ~= false then
			command = command .. " " .. name .. "=" .. quote(value)
		end
	end
	if env.PATH then
		command = command .. " PATH=" .. quote(env.PATH)
	end
	command = command .. " " .. quote(lua) .. " " .. quote(script or generator)
	if output ~= nil then
		command = command .. " " .. quote(output)
	end
	local ok = os.execute(command .. " >" .. quote(root .. "/stdout") .. " 2>" .. quote(root .. "/stderr"))
	return ok == true, read(root .. "/stdout"), read(root .. "/stderr")
end

local function test(name, body)
	local root = os.tmpname()
	assert(os.remove(root))
	mkdir(root)
	local ok, err = xpcall(function() body(root) end, debug.traceback)
	assert(os.execute("rm -rf " .. quote(root)))
	if ok then
		passed = passed + 1
		print("ok - " .. name)
	else
		failed = failed + 1
		io.stderr:write("not ok - " .. name .. "\n" .. err .. "\n")
	end
end

test("preflights both targets before writing when either exists", function(root)
	for _, names in ipairs({ { "modules.lua" }, { "config.lua" }, { "modules.lua", "config.lua" } }) do
		local output = root .. "/" .. table.concat(names, "-")
		mkdir(output)
		for _, name in ipairs(names) do
			write(output .. "/" .. name, "user-owned " .. name .. "\n")
		end
		local ok, _, err = run(root, output)
		assert(not ok, "generator must refuse existing configuration")
		assert(err:find("exist", 1, true), "refusal must be visible on stderr: " .. err)
		for _, name in ipairs({ "modules.lua", "config.lua" }) do
			local exists = false
			for _, existing in ipairs(names) do
				exists = exists or existing == name
			end
			if exists then
				assert(read(output .. "/" .. name) == "user-owned " .. name .. "\n", name .. " was overwritten")
			else
				absent(output .. "/" .. name)
			end
		end
	end
end)

test("discovers sorted directory names without executing module source", function(root)
	local source = root .. "/source"
	mkdir(source .. "/scripts")
	write(source .. "/scripts/generate-config.lua", read(generator))
	for _, name in ipairs({ "z-last", "a-first" }) do
		mkdir(source .. "/wezmacs/modules/" .. name)
		write(
			source .. "/wezmacs/modules/" .. name .. "/init.lua",
			'error("do not execute"); return { name = "wrong-name" }'
		)
	end
	mkdir(source .. "/wezmacs/modules/ignored")
	write(source .. "/wezmacs/modules/not-a-module.lua", "return {}")
	local output = root .. "/generated"
	local ok, _, err = run(root, output, nil, source .. "/scripts/generate-config.lua")
	assert(ok, err)
	local modules = assert(loadfile(output .. "/modules.lua"))()
	assert(type(modules) == "table", "modules.lua must return a table")
	assert(table.concat(modules, ",") == "a-first,z-last", "use directory names, not spec metadata")
	assert(type(assert(loadfile(output .. "/config.lua"))()) == "table", "config.lua must return a table")
end)

test("resolves explicit output before WEZMACSDIR, XDG_CONFIG_HOME, and HOME", function(root)
	local cases = {
		{ output = "explicit", expected = "explicit" },
		{ expected = "WEZMACSDIR" },
		{ wezmacs = false, expected = "XDG_CONFIG_HOME/wezmacs" },
		{ wezmacs = false, xdg = false, expected = "HOME/.config/wezmacs" },
		{ wezmacs = "", xdg = "", expected = "HOME/.config/wezmacs" },
	}
	for index, case in ipairs(cases) do
		local sandbox = root .. "/" .. index
		mkdir(sandbox)
		local output = case.output and sandbox .. "/" .. case.output
		local ok, _, err = run(sandbox, output, { WEZMACSDIR = case.wezmacs, XDG_CONFIG_HOME = case.xdg })
		assert(ok, err)
		local expected = sandbox .. "/" .. case.expected
		assert(type(assert(loadfile(expected .. "/config.lua"))()) == "table")
		assert(type(assert(loadfile(expected .. "/modules.lua"))()) == "table")
		for _, candidate in ipairs({ "explicit", "WEZMACSDIR", "XDG_CONFIG_HOME/wezmacs", "HOME/.config/wezmacs" }) do
			if candidate ~= case.expected then
				absent(sandbox .. "/" .. candidate .. "/config.lua")
				absent(sandbox .. "/" .. candidate .. "/modules.lua")
			end
		end
	end
end)

test("real checkout generates loadable templates without stale settings", function(root)
	local output = root .. "/generated"
	local ok, stdout, err = run(root, output)
	assert(ok, err)
	local config = assert(loadfile(output .. "/config.lua"))()
	assert(type(config) == "table" and next(config) == nil, "leave global defaults unchanged")
	local modules = assert(loadfile(output .. "/modules.lua"))()
	assert(type(modules) == "table" and #modules > 0, "enable existing modules")
	for index, name in ipairs(modules) do
		read(repo .. "/wezmacs/modules/" .. name .. "/init.lua")
		assert(index == 1 or modules[index - 1] < name, "modules must be sorted and unique")
	end
	local generated = read(output .. "/config.lua") .. read(output .. "/modules.lua") .. stdout
	for _, stale in ipairs({ "mod_key", "leader_key", "leader_mod", "agent", "example/wezterm.lua" }) do
		assert(not generated:find(stale, 1, true), "stale generated setting or instruction: " .. stale)
	end
end)

test("quotes unusual relative output paths and preserves the generated pair", function(root)
	local relative = "- user's $(touch injected) `touch also-injected`; literal\npath"
	local output = root .. "/" .. relative
	local ok, _, err = run(root, relative .. "///")
	assert(ok, err)
	local original = {}
	for _, name in ipairs({ "modules.lua", "config.lua" }) do
		original[name] = read(output .. "/" .. name)
		assert(type(assert(loadfile(output .. "/" .. name))()) == "table")
	end
	ok, _, err = run(root, relative)
	assert(not ok and err:find("exist", 1, true), "a second run must refuse the pair")
	for name, content in pairs(original) do
		assert(read(output .. "/" .. name) == content, name .. " changed on the second run")
	end
	absent(root .. "/injected")
	absent(root .. "/also-injected")
end)

test("reports missing modules before creating output files", function(root)
	mkdir(root .. "/scripts")
	write(root .. "/scripts/generate-config.lua", read(generator))
	local output = root .. "/generated"
	local ok, _, err = run(root, output, nil, root .. "/scripts/generate-config.lua")
	assert(not ok, "missing module tree must fail, not generate an empty manifest")
	assert(err:find("modules", 1, true), "failure must identify module discovery: " .. err)
	absent(output .. "/modules.lua")
	absent(output .. "/config.lua")
end)

test("reports write failures instead of claiming success", function(root)
	local output = root .. "/generated"
	-- A zero file-size limit makes real writes fail even when running as root.
	-- Keep diagnostics in a pipe so the same limit does not hide the error.
	local command = "cd "
		.. quote(root)
		.. " && ulimit -f 0 && trap '' XFSZ && env "
		.. "HOME="
		.. quote(root .. "/HOME")
		.. " XDG_CONFIG_HOME="
		.. quote(root .. "/XDG_CONFIG_HOME")
		.. " WEZMACSDIR="
		.. quote(root .. "/WEZMACSDIR")
		.. " "
		.. quote(lua)
		.. " "
		.. quote(generator)
		.. " "
		.. quote(output)
		.. " 2>&1"
	local pipe = assert(io.popen(command))
	local message = assert(pipe:read("*a"))
	local ok = pipe:close()
	assert(not ok, "generator must fail when writing fails: " .. message)
	assert(message:find("modules.lua", 1, true), "error must identify the failed file: " .. message)
	absent(output .. "/config.lua")
end)

test("does not overwrite a file created after preflight", function(root)
	mkdir(root .. "/bin")
	-- Simulate another writer between preflight and the first output write.
	write(root .. "/bin/mkdir", '#!/bin/sh\n/bin/mkdir "$@" || exit\nprintf "%s" "other writer" > "$2/modules.lua"\n')
	assert(os.execute("chmod +x " .. quote(root .. "/bin/mkdir")))
	local output = root .. "/generated"
	local ok, _, err = run(root, output, { PATH = root .. "/bin:" .. assert(os.getenv("PATH")) })
	assert(not ok, "must refuse files created after preflight")
	assert(err:find("modules.lua", 1, true), "error must identify the conflicting file: " .. err)
	assert(read(output .. "/modules.lua") == "other writer", "concurrent file was overwritten")
	absent(output .. "/config.lua")
end)

test("rejects an empty explicit output directory", function(root)
	local ok, _, err = run(root, "")
	assert(not ok, "an empty output argument must not silently target the working directory")
	assert(err:find("output", 1, true), "error must identify the output argument: " .. err)
	absent(root .. "/config.lua")
	absent(root .. "/modules.lua")
end)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
