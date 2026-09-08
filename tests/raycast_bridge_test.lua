-- Native serialization fixture: run this config with show-keys --lua and
-- WEZMACS_RAYCAST_NATIVE_TEST=1. All local discovery is replaced, never launches.
if os.getenv("WEZMACS_RAYCAST_NATIVE_TEST") == "1" then
	local w = require("wezterm")
	w.home_dir = "/nonexistent-raycast-native-test-home"
	w.enumerate_ssh_hosts = function() return {} end
	w.read_dir = function() return {} end
	w.run_child_process = function() return false, "", "" end
	w.background_child_process = function() error("Native test must not launch.") end
	local stderr, messages = io.stderr, {}
	rawset(io, "stderr", { write = function(_, text) messages[#messages + 1] = text end })
	local config = dofile(assert(os.getenv("WEZMACS_RAYCAST_ROOT")) .. "/scripts/raycast.lua")
	io.stderr = stderr
	assert(#messages == 1 and messages[1]:find('"choices":[]', 1, true), "empty choices must serialize as an array")
	io.stderr:write(messages[1])
	return config
end

package.path = "./?.lua;./?/init.lua;" .. package.path

local count = 0
local request, result, output, native, config
local original_path = package.path
local function run(value)
	request, result, output = value, nil, ""
	local w = {
		home_dir = "/nonexistent-raycast-test-home",
		executable_dir = "/native",
		target_triple = "aarch64-apple-darwin",
		enumerate_ssh_hosts = function() return { Work = { hostname = "redirected.example", port = "2222" } } end,
		run_child_process = function(argv)
			assert(argv[2] == "query" and argv[3] == "-l", "only read-only discovery")
			return true, "", ""
		end,
		background_child_process = function() return true end,
		read_dir = function() return {} end,
		mux = { get_workspace_names = function() error("headless collection must not query native mux") end },
		json_parse = function(text)
			assert(text == "request-json", "unexpected JSON source")
			return request
		end,
		json_encode = function(data)
			result = data
			return "encoded-result"
		end,
		config_builder = function()
			return { set_strict_mode = function() end }
		end,
		action = { SendString = function(text) return { SendString = text } end },
	}
	local workspace_names = w.mux.get_workspace_names
	native = w
	package.loaded.wezterm = w
	package.loaded["wezmacs.modules.mux.hosts"] = nil
	package.loaded["wezmacs.modules.mux.workspaces"] = nil
	local env = setmetatable({
		require = function(name)
			assert(
				name == "wezterm" or name == "wezmacs.modules.mux.hosts" or name == "wezmacs.modules.mux.workspaces",
				"unexpected module " .. name
			)
			return require(name)
		end,
		os = {
			getenv = function(name)
				if name == "WEZMACS_RAYCAST_ROOT" then
					return "."
				end
				if name == "WEZMACS_RAYCAST_REQUEST" then
					return "request-json"
				end
			end,
			exit = function(code) error("EXIT:" .. code, 0) end,
		},
		io = { stderr = { write = function(_, text) output = output .. text end } },
	}, { __index = _G })
	local chunk, err = loadfile("scripts/raycast.lua", "t", env)
	assert(chunk, "headless bridge missing: " .. tostring(err))
	local ok, value_or_error = pcall(chunk)
	config = ok and value_or_error or nil
	package.path = original_path
	assert(w.mux.get_workspace_names == workspace_names, "bridge must not replace the native inventory API")
	return ok, value_or_error
end
local function test(name, fn)
	fn()
	count = count + 1
	print("PASS " .. name)
end

test("headless hosts returns shared discovery and a native success sentinel", function()
	assert(run({ op = "hosts" }))
	assert(result.ok == true and type(result.data.meta.targets) == "table")
	local found = false
	for _, choice in ipairs(result.data.choices) do
		if result.data.meta.targets[choice.id].target == "Work" then
			found = true
		end
	end
	assert(found, "shared configured alias returned")
	assert(output == "WEZMACS_RAYCAST_RESULT encoded-result\n")
	assert(config.keys[1].key == "F24" and config.keys[1].action.SendString == "WEZMACS_RAYCAST_OK")
	assert(not pcall(native.background_child_process, { "unwanted" }), "headless helper must block launches")
end)

test("workspace discovery uses only supplied live workspace names", function()
	assert(run({ op = "workspaces", workspaces = { "remote-live", "named-live" } }))
	assert(result.ok and result.data.choices[1].id == "remote-live" and result.data.choices[2].id == "named-live")
	assert(run({ op = "workspaces", workspaces = {} }))
	assert(result.ok and #result.data.choices == 0, "cold inventory is valid")
	for _, value in ipairs({ false, "bad", { false }, { [2] = "sparse" }, { name = "map" }, { "bad\nname" } }) do
		local ok, err = run({ op = "workspaces", workspaces = value })
		assert(not ok and err == "EXIT:1", "invalid workspace inventory exits nonzero")
		assert(result.ok == false and type(result.error) == "string")
	end
end)

test("SSH plan bridge returns shared argv and rejects unsafe or stale selection", function()
	assert(run({ op = "ssh-plan", selection = { input = " Alice@Work:22 " } }))
	assert(result.ok and table.concat(result.data.argv, " | ") == "/native/wezterm | ssh | -- | Alice@Work:22")
	assert(run({ op = "ssh-plan", selection = { target = "192.0.2.1", source = "known-host" } }))
	assert(result.data.argv[4] == "HostName=192.0.2.1" and result.data.argv[8] == "192.0.2.1:22")
	for _, selection in ipairs({
		false,
		{},
		{ input = "host;id" },
		{ target = "peer.example", source = "tailscale", identity = "old", peer_id = "one", key = "peer.example:22" },
	}) do
		local ok, err = run({ op = "ssh-plan", selection = selection })
		assert(not ok and err == "EXIT:1" and result.ok == false and type(result.error) == "string")
	end
end)

test("unknown and malformed bridge requests fail without a success config", function()
	for _, value in ipairs({
		false,
		42,
		"host",
		{},
		{ op = "execute", argv = { "touch", "unwanted" } },
		{ op = "ssh-plan" },
	}) do
		local ok, err = run(value)
		assert(not ok and err == "EXIT:1" and not config)
		assert(result.ok == false and type(result.error) == "string")
		assert(output == "WEZMACS_RAYCAST_RESULT encoded-result\n")
	end
end)

print("PASS raycast bridge: " .. count .. " tests (" .. _VERSION .. ")")
