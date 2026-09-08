package.path = "./?.lua;./?/init.lua;" .. package.path

---@class HostTestSelector
---@field title string
---@field fuzzy boolean
---@field fuzzy_description string
---@field description string
---@field choices {id:string, label:string}[]
---@field action fun(window:table, pane:table, id:string?, label:string?)
---@type HostTestSelector?
local selected
local function picker()
	assert(selected, "picker was not opened")
	return selected
end
local aliases, runs, spawns, toasts = {}, {}, {}, {}
local status, run_error, spawn_error, json_error, enumerate_error, run_success
local wezterm = {
	home_dir = "/nonexistent-host-test-home",
	executable_dir = "/Applications/WezTerm.app/Contents/MacOS",
	enumerate_ssh_hosts = function()
		if enumerate_error then
			error(enumerate_error)
		end
		return aliases
	end,
	run_child_process = function(argv)
		runs[#runs + 1] = argv
		if run_error then
			error(run_error)
		end
		return run_success ~= false, "fixture-json", ""
	end,
	json_parse = function()
		if json_error then
			error(json_error)
		end
		return status
	end,
	background_child_process = function(argv)
		if spawn_error then
			error(spawn_error)
		end
		spawns[#spawns + 1] = argv
	end,
	action_callback = function(fn) return fn end,
	action = { InputSelector = function(spec) return spec end },
}
package.loaded.wezterm = wezterm
local hosts = require("wezmacs.modules.mux.hosts")
local window = {
	perform_action = function(_, action) selected = action end,
	toast_notification = function(_, _, message) toasts[#toasts + 1] = message end,
}
local count = 0
local function test(name, fn)
	aliases, runs, spawns, selected, toasts = {}, {}, {}, nil, {}
	status, run_error, spawn_error, json_error, enumerate_error, run_success = nil, nil, nil, nil, nil, nil
	fn()
	count = count + 1
	print("PASS " .. name)
end
local function equal(actual, expected, message)
	assert(
		actual == expected,
		(message or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)
	)
end
local function targets(meta)
	local result = {}
	for _, row in pairs(meta.targets) do
		result[row.target] = row
	end
	return result
end
local function fixture(text, fn)
	local path = os.tmpname()
	local file = assert(io.open(path, "w"))
	file:write(text)
	file:close()
	local ok, err = pcall(fn, path)
	os.remove(path)
	assert(ok, err)
end

test("concrete aliases union readable known_hosts without unsafe entries", function()
	aliases = { Work = {}, ["*.example"] = {}, ["!blocked"] = {}, ["-oProxyCommand=x"] = {} }
	fixture(
		[[# comment
Work,server.example ssh-ed25519 AAAA
[server.example]:22 ssh-ed25519 AAAA
[server.example]:2222 ssh-ed25519 AAAA
|1|salt|hash ssh-ed25519 AAAA
@revoked revoked.example ssh-ed25519 AAAA
@cert-authority ca.example ssh-ed25519 AAAA
bad;command ssh-ed25519 AAAA
[2001:db8::1]:2200 ssh-ed25519 AAAA
]],
		function(path)
			local choices, meta = hosts.get_choices({ tailscale = false, known_hosts_files = { path, path .. ".missing" } })
			local found = targets(meta)
			equal(#choices, 4, "safe deduplicated choices")
			assert(found.Work and found["server.example"] and found["server.example:2222"] and found["[2001:db8::1]:2200"])
			equal(found.Work.source, "alias")
			equal(#runs, 0, "disabled discovery never spawns")
		end
	)
end)

test("endpoint grammar rejects malformed hosts, users, ports and IPv6", function()
	local bad = {
		"-host",
		"a b",
		"a\nb",
		"a\tb",
		"a;b",
		"a|b",
		"a&b",
		"a$(id)",
		"a`id`",
		"a*",
		"a?",
		"!a",
		"a/b",
		"a\\b",
		"a'",
		'a"',
		"user@@host",
		"-user@host",
		"host:0",
		"host:65536",
		"host:-1",
		"host:2.2",
		"host:abc",
		"host:",
		"[::1]:",
		"[::1]:abc",
		"[::gg]",
		"[1::2::3]",
		"[:::]",
		"[1:2:3]",
		"[1:2:3:4:5:6:7:8:9]",
		"[12345::1]",
		"host..example",
		".host",
		"host.-bad",
		"host-.example",
		"999.2.3.4",
	}
	for _, name in ipairs(bad) do
		aliases[name] = {}
	end
	aliases["good.example"] = {}
	fixture(
		"[2001:DB8::1]:22 ssh-ed25519 AAAA\n[2001:0db8:0:0:0:0:0:1]:22 ssh-ed25519 AAAA\nGOOD.EXAMPLE. ssh-ed25519 AAAA\n",
		function(path)
			local choices = hosts.get_choices({ tailscale = false, known_hosts_files = { path } })
			equal(#choices, 2, "only valid normalized endpoints")
		end
	)
end)

test("configured endpoints win dedupe without losing users or nondefault ports", function()
	aliases = {
		Admin = { hostname = "server.example", user = "admin", port = "22", identityfile = "/fixture/key" },
		Deploy = { hostname = "SERVER.EXAMPLE.", user = "deploy", port = "22" },
		Backup = { hostname = "server.example", user = "admin", port = "2222" },
		["alice@same.example"] = {},
		["bob@same.example"] = {},
	}
	fixture(
		"server.example ssh-ed25519 AAAA\n[server.example]:2222 ssh-ed25519 AAAA\n[server.example]:2200 ssh-ed25519 AAAA\n",
		function(path)
			local choices, meta = hosts.get_choices({ tailscale = false, known_hosts_files = { path } })
			equal(#choices, 6)
			local found = targets(meta)
			assert(
				found.Admin and found.Deploy and found.Backup and found["alice@same.example"] and found["bob@same.example"]
			)
			assert(found["server.example:2200"] and not found["server.example"] and not found["server.example:2222"])
		end
	)
end)

local function tailnet(name)
	return {
		BackendState = "Running",
		CurrentTailnet = { Name = name, MagicDNSSuffix = name .. ".ts.net" },
		Self = { ID = "self", UserID = 100 },
		Peer = {
			p1 = {
				ID = "one",
				DNSName = "desktop." .. name .. ".ts.net.",
				TailscaleIPs = { "100.64.0.1" },
				Online = true,
				OS = "linux",
			},
			p2 = { ID = "two", DNSName = "phone." .. name .. ".ts.net.", Online = false, OS = "iOS" },
			p3 = { ID = "personal-exit", DNSName = "exit." .. name .. ".ts.net.", Online = true, ExitNodeOption = true },
			provider = { ID = "provider", DNSName = "provider.example.", Location = { Country = "US" }, Online = true },
			self = { ID = "self", DNSName = "self.example.", Online = true },
			ip = { ID = "ip", HostName = "unsafe-short-name", TailscaleIPs = { "fd7a::1", "100.64.0.2" }, Online = true },
			short = { ID = "short", HostName = "collision", DNSName = "not-fqdn" },
		},
	}
end
local opts = { known_hosts_files = {}, tailscale_path = "/fixture/Tailscale binary" }

test("short tailnet targets match SSH User rules but pin the full transport host", function()
	status = tailnet("alpha")
	status.Peer = { p1 = status.Peer.p1 }
	local _, meta = hosts.get_choices(opts)
	local row = targets(meta).desktop
	assert(row, "tailnet picker must expose short desktop hostname")
	equal(row.key, "desktop.alpha.ts.net:22", "full peer identity retained")
	local argv = assert(hosts.launch_args(row, opts))
	equal(argv[#argv], "desktop:22", "short name selects SSH User rule")
	equal(argv[4], "HostName=desktop.alpha.ts.net", "transport cannot follow an unrelated short alias")
end)

test("current local tailnet discovery labels ordinary devices without probes", function()
	status = tailnet("alpha")
	local choices, meta = hosts.get_choices(opts)
	equal(#choices, 4)
	equal(meta.tailnet, "alpha")
	assert(meta.status:find("alpha", 1, true))
	local found = targets(meta)
	assert(found.desktop and found.phone and found.exit and found["100.64.0.2"])
	local labels = {}
	for _, choice in ipairs(choices) do
		labels[meta.targets[choice.id].target] = choice.label
	end
	assert(labels.phone:find("offline", 1, true) and labels.phone:find("iOS", 1, true))
	assert(labels.desktop:find("online", 1, true))
	equal(#runs, 1, "one local status read only")
	local argv = runs[1]
	equal(argv[1], "/usr/bin/perl")
	equal(argv[2], "-e")
	assert(argv[3]:find("alarm shift; exec @ARGV", 1, true))
	equal(argv[4], "3")
	equal(argv[5], opts.tailscale_path)
	equal(argv[6], "status")
	equal(argv[7], "--json")
	equal(#argv, 7)
	equal(#spawns, 0)
end)

test("tailnet DNS and IP dedupe retains nondefault aliases", function()
	status = tailnet("alpha")
	aliases = {
		Personal = { hostname = "100.64.0.1", port = "22", user = "admin" },
		["phone.alpha.ts.net"] = { hostname = "phone.alpha.ts.net", port = "2222" },
	}
	fixture(
		"100.64.0.1 ssh-ed25519 AAAA\ndesktop.alpha.ts.net ssh-ed25519 AAAA\n100.64.0.2 ssh-ed25519 AAAA\n[100.64.0.2]:2222 ssh-ed25519 AAAA\n",
		function(path)
			local choices, meta = hosts.get_choices({ known_hosts_files = { path }, tailscale_path = opts.tailscale_path })
			equal(#choices, 6)
			local found = targets(meta)
			assert(found.Personal and not found["100.64.0.1"] and not found["desktop.alpha.ts.net"])
			equal(found["100.64.0.2"].source, "tailscale")
			assert(found["100.64.0.2:2222"])
			local phone = 0
			for _, row in pairs(meta.targets) do
				if row.target == "phone.alpha.ts.net" then
					phone = phone + 1
				end
			end
			equal(phone, 1, "full-name alias retained separately from short tailnet target")
			assert(found.phone, "short tailnet target retained at port22")
		end
	)
end)

test("HOSTS-002 redirected aliases dedupe only their resolved endpoint", function()
	status = tailnet("alpha")
	status.Peer = { p1 = status.Peer.p1 }
	aliases = { ["desktop.alpha.ts.net"] = { hostname = "REDIRECTED.EXAMPLE.", port = "22", user = "deploy" } }
	fixture("desktop.alpha.ts.net ssh-ed25519 AAAA\nredirected.example ssh-ed25519 AAAA\n", function(path)
		for _, source in ipairs({ "tailscale", "known-host" }) do
			local choices, meta = hosts.get_choices({
				tailscale = source == "tailscale",
				tailscale_path = opts.tailscale_path,
				known_hosts_files = { path },
			})
			equal(#choices, 2, "redirected alias and distinct " .. source .. " endpoint remain available")
			local by_source = {}
			for _, row in pairs(meta.targets) do
				equal(row.target, row.source == "tailscale" and "desktop" or "desktop.alpha.ts.net", "source-specific target")
				assert(not by_source[row.source], "only one row per source")
				by_source[row.source] = row
			end
			assert(by_source.alias, "configured alias is preserved")
			assert(by_source[source], "raw alias-spelling endpoint is distinct from redirected HostName")
			equal(by_source[source].key, "desktop.alpha.ts.net:22")
		end
	end)
	equal(#spawns, 0, "discovery never connects")
end)

test("each picker open refreshes the current account and cancel never spawns", function()
	local action = hosts.switch_host(opts)
	equal(#runs, 0, "construction is lazy")
	status = tailnet("alpha")
	action(window, {})
	assert(picker().title:find("alpha", 1, true))
	equal(picker().fuzzy, true)
	equal(picker().fuzzy_description, "SSH hosts: ")
	equal(picker().description, "Select an SSH host")
	local first = picker()
	status = tailnet("beta")
	action(window, {})
	assert(picker().title:find("beta", 1, true) and not picker().title:find("alpha", 1, true))
	for _, choice in ipairs(picker().choices) do
		assert(not choice.label:find("alpha", 1, true))
	end
	equal(#runs, 2)
	first.action(window, {}, nil, nil)
	picker().action(window, {}, nil, nil)
	equal(#runs, 2, "cancel does not even recheck")
	equal(#spawns, 0)
end)

test("distinct configured aliases retain distinct SSH options", function()
	aliases = {
		First = { hostname = "same.example", user = "same", identityfile = "/key/one" },
		Second = { hostname = "same.example", user = "same", identityfile = "/key/two" },
	}
	local choices, meta = hosts.get_choices({ tailscale = false, known_hosts_files = {} })
	equal(#choices, 2)
	assert(targets(meta).First and targets(meta).Second)
end)

local function choice_id(text)
	for _, choice in ipairs(picker().choices) do
		if choice.label:find(text, 1, true) == 1 then
			return choice.id
		end
	end
	error("missing fixture choice " .. text)
end

test("explicit alias selection launches only safe native argv and preserves alias", function()
	aliases = { Work = { hostname = "server.example", user = "deploy", port = "2222", identityfile = "/fixture/key" } }
	hosts.switch_host({ tailscale = false, known_hosts_files = {} })(window, {})
	local id = choice_id("Work")
	picker().action(window, {}, "forged;id", "malicious")
	equal(#spawns, 0)
	aliases = {}
	picker().action(window, {}, id, ";not-used")
	equal(#spawns, 1)
	local argv = spawns[1]
	equal(#argv, 4)
	equal(argv[1], wezterm.executable_dir .. "/wezterm")
	equal(argv[2], "ssh")
	equal(argv[3], "--")
	equal(argv[4], "Work")
	equal(#runs, 0, "static selection never checks a remote or tailnet")
end)

test("HOSTS-004 IPv6 and malformed resolved HostNames never claim alias spelling", function()
	status = tailnet("alpha")
	status.Peer = { p1 = status.Peer.p1 }
	local actual, expected = {}, {}
	for _, case in ipairs({
		{ hostname = "fd7a:115c:a1e0::99", known = "[FD7A:115C:A1E0:0:0:0:0:99]:22" },
		{
			hostname = "FD7A:115C:A1E0:0000:0000:0000:0000:0099",
			port = "2200",
			known = "[fd7a:115c:a1e0::99]:2200",
		},
		{ hostname = "[fd7a:115c:a1e0::99]", port = "22", known = "[fd7a:115c:a1e0::99]:22" },
		{ hostname = "fd7a:115c:a1e0:::99", port = "22" },
		{ hostname = "not a host", port = "22" },
	}) do
		aliases = { ["desktop.alpha.ts.net"] = { hostname = case.hostname, port = case.port } }
		local text = "desktop.alpha.ts.net ssh-ed25519 AAAA\n"
			.. (case.known and (case.known .. " ssh-ed25519 AAAA\n") or "")
		fixture(text, function(path)
			for _, source in ipairs({ "tailscale", "known-host" }) do
				local options = {
					tailscale = source == "tailscale",
					tailscale_path = opts.tailscale_path,
					known_hosts_files = { path },
				}
				local _, meta = hosts.get_choices(options)
				local rows = {}
				for _, row in pairs(meta.targets) do
					rows[#rows + 1] = row.source .. ":" .. row.target
				end
				table.sort(rows)
				local label = case.hostname .. " / " .. source .. ": "
				actual[#actual + 1] = label .. table.concat(rows, ", ")
				expected[#expected + 1] = label
					.. "alias:desktop.alpha.ts.net, "
					.. source
					.. (source == "tailscale" and ":desktop" or ":desktop.alpha.ts.net")
				hosts.switch_host(options)(window, {})
				local before = #spawns
				picker().action(window, {}, choice_id("desktop.alpha.ts.net [alias]"), nil)
				equal(#spawns, before + 1, "IPv6 resolution does not block configured-alias launch")
				equal(
					table.concat(spawns[#spawns], " | "),
					wezterm.executable_dir .. "/wezterm | ssh | -- | desktop.alpha.ts.net",
					"configured alias is passed literally without raw overrides"
				)
			end
		end)
	end
	equal(
		table.concat(actual, "\n"),
		table.concat(expected, "\n"),
		"dedupe only valid resolved endpoints for both sources"
	)
	equal(#toasts, 0, "IPv6 transport through a configured alias remains supported")
end)

test("HOSTS-003 both raw sources disable an inherited redirected ProxyCommand", function()
	status = tailnet("alpha")
	status.Peer = { p1 = status.Peer.p1 }
	aliases = {
		["desktop.alpha.ts.net"] = {
			hostname = "redirected.example",
			port = "2222",
			proxycommand = "/usr/bin/nc %h %p",
		},
	}
	local raw_argv = {}
	fixture("desktop.alpha.ts.net ssh-ed25519 AAAA\n", function(path)
		for _, case in ipairs({
			{ tailscale = true, label = "desktop [online;" },
			{ tailscale = false, label = "desktop.alpha.ts.net [known-host]" },
		}) do
			hosts.switch_host({
				tailscale = case.tailscale,
				tailscale_path = opts.tailscale_path,
				known_hosts_files = { path },
			})(window, {})
			picker().action(window, {}, choice_id(case.label), nil)
			raw_argv[#raw_argv + 1] = table.concat(spawns[#spawns], " | ")
			picker().action(window, {}, choice_id("desktop.alpha.ts.net [alias]"), nil)
			equal(
				table.concat(spawns[#spawns], " | "),
				wezterm.executable_dir .. "/wezterm | ssh | -- | desktop.alpha.ts.net",
				"configured proxy alias stays literal without overrides"
			)
		end
	end)
	local expected = wezterm.executable_dir
		.. "/wezterm | ssh | -o | HostName=desktop.alpha.ts.net | -o | ProxyCommand=none | -- | desktop.alpha.ts.net:22"
	equal(
		table.concat(raw_argv, "\n"),
		expected:gsub("%-%- | desktop.alpha.ts.net:22$", "-- | desktop:22") .. "\n" .. expected,
		"Tailscale and known-host raw argv"
	)
	equal(#spawns, 4, "each raw endpoint and alias launches once into the stub")
	equal(#runs, 2, "only Tailscale opening and submission read local status")
	equal(#toasts, 0)
end)

test("HOSTS-001 raw destinations override a same-named alias HostName", function()
	status = tailnet("alpha")
	status.Peer = { p1 = status.Peer.p1 }
	aliases = { ["desktop.alpha.ts.net"] = { hostname = "redirected.example", port = "2222", user = "deploy" } }
	fixture("desktop.alpha.ts.net ssh-ed25519 AAAA\n[desktop.alpha.ts.net]:2200 ssh-ed25519 AAAA\n", function(path)
		for _, case in ipairs({
			{ tailscale = true, label = "desktop [online;", target = "desktop:22" },
			{ tailscale = false, label = "desktop.alpha.ts.net [known-host]", target = "desktop.alpha.ts.net:22" },
			{ tailscale = false, label = "desktop.alpha.ts.net:2200 [known-host]", target = "desktop.alpha.ts.net:2200" },
		}) do
			local before, run_before = #spawns, #runs
			hosts.switch_host({
				tailscale = case.tailscale,
				tailscale_path = opts.tailscale_path,
				known_hosts_files = { path },
			})(window, {})
			picker().action(window, {}, choice_id(case.label), "redirected.example")
			equal(#spawns, before + 1, "raw selection launches once")
			equal(#runs, run_before + (case.tailscale and 2 or 0), "only tailnet selection rechecks local status")
			local argv = spawns[#spawns]
			equal(argv[1], wezterm.executable_dir .. "/wezterm")
			equal(argv[2], "ssh")
			equal(argv[3], "-o", "raw destination needs a native SSH option")
			equal(argv[4], "HostName=desktop.alpha.ts.net", "validated represented host overrides redirected HostName")
			equal(argv[5], "-o")
			equal(argv[6], "ProxyCommand=none")
			equal(argv[7], "--")
			equal(argv[8], case.target, "represented port is explicit")
			equal(#argv, 8)
			picker().action(window, {}, choice_id("desktop.alpha.ts.net [alias]"), nil)
			local alias_argv = spawns[#spawns]
			equal(#spawns, before + 2, "redirected alias remains selectable")
			equal(#alias_argv, 4, "alias launch gains no overrides")
			equal(alias_argv[1], wezterm.executable_dir .. "/wezterm")
			equal(alias_argv[2], "ssh")
			equal(alias_argv[3], "--")
			equal(alias_argv[4], "desktop.alpha.ts.net", "configured alias stays exact")
			equal(#toasts, 0)
		end
	end)
end)

test("tailnet selection rechecks identity and exact peer endpoint before launch", function()
	local changes = {
		function() status = tailnet("beta") end,
		function() status.Self.UserID = 200 end,
		function() status.Peer.p1 = nil end,
		function() status.Peer.p1.ID = "replacement" end,
		function() status.Peer.p1.DNSName = "renamed.alpha.ts.net." end,
		function() run_error = "missing binary" end,
	}
	for _, change in ipairs(changes) do
		status, run_error = tailnet("alpha"), nil
		hosts.switch_host(opts)(window, {})
		local id = choice_id("desktop")
		change()
		local before = #runs
		picker().action(window, {}, id, nil)
		equal(#spawns, 0, "stale selection must not spawn")
		equal(#runs, before + 1, "submission reads only current local status")
		assert(toasts[#toasts]:find("changed or unavailable", 1, true))
	end
	status, run_error = tailnet("alpha"), nil
	hosts.switch_host(opts)(window, {})
	picker().action(window, {}, choice_id("desktop"), nil)
	equal(#spawns, 1, "unchanged current peer can launch")
	equal(spawns[1][#spawns[1]], "desktop:22")
end)

test("optional discovery failures preserve static hosts with clear status", function()
	local cases = {
		{ function() run_error = "missing perl or tailscale" end, "unavailable" },
		{ function() run_success = false end, "unavailable" },
		{ function() json_error = "invalid json" end, "invalid JSON" },
		{ function() status = "not a table" end, "invalid JSON" },
		{ function() status.BackendState = "Stopped" end, "not Running" },
		{ function() status.CurrentTailnet = nil end, "missing identity" },
		{ function() status.Peer = nil end, "no eligible peers" },
		{ function() status.Peer = { broken = { TailscaleIPs = 42 } } end, "no eligible peers" },
	}
	fixture("static.example ssh-ed25519 AAAA\n", function(path)
		for _, case in ipairs(cases) do
			status, run_error, json_error, run_success = tailnet("alpha"), nil, nil, nil
			aliases = { Work = {} }
			case[1]()
			local choices, meta = hosts.get_choices({ known_hosts_files = { path }, tailscale_path = opts.tailscale_path })
			equal(#choices, 2)
			assert(meta.status:find(case[2], 1, true), meta.status)
		end
		enumerate_error = "SSH config failure"
		local choices, meta = hosts.get_choices({ tailscale = false, known_hosts_files = { path } })
		equal(#choices, 1)
		assert(meta.status:find("SSH config unavailable", 1, true))
	end)
end)

test("raw default-port selection cannot inherit a configured nondefault port", function()
	status = tailnet("alpha")
	aliases = { ["phone.alpha.ts.net"] = { hostname = "phone.alpha.ts.net", port = "2222" } }
	hosts.switch_host(opts)(window, {})
	for _, choice in ipairs(picker().choices) do
		if choice.label:find("phone", 1, true) == 1 then
			picker().action(window, {}, choice.id, nil)
		end
	end
	local sent = {}
	for _, argv in ipairs(spawns) do
		sent[argv[#argv]] = true
	end
	assert(sent["phone.alpha.ts.net"], "alias stays exact for SSH config")
	assert(sent["phone:22"], "raw default endpoint explicitly overrides SSH config Port")
	fixture("[phone.alpha.ts.net]:22 ssh-ed25519 AAAA\n", function(path)
		hosts.switch_host({ tailscale = false, known_hosts_files = { path } })(window, {})
		for _, choice in ipairs(picker().choices) do
			if choice.label:find("known-host", 1, true) then
				picker().action(window, {}, choice.id, nil)
			end
		end
		equal(spawns[#spawns][#spawns[#spawns]], "phone.alpha.ts.net:22")
	end)
end)

test("immediate native spawn errors toast rather than escape the callback", function()
	aliases = { Work = {} }
	hosts.switch_host({ tailscale = false, known_hosts_files = {} })(window, {})
	spawn_error = "cannot spawn"
	local ok = pcall(picker().action, window, {}, choice_id("Work"), nil)
	assert(ok, "spawn failure must be protected")
	equal(#spawns, 0)
	assert(toasts[#toasts]:find("Could not start", 1, true))
end)

test("unreadable known_hosts directory cannot abort optional discovery", function()
	aliases = { Work = {} }
	local choices, meta = hosts.get_choices({ tailscale = false, known_hosts_files = { "." } })
	equal(#choices, 1)
	assert(meta.status:find("known_hosts unreadable", 1, true))
end)

test("binary discovery uses PATH then Mac fallbacks without unbounded probes", function()
	local original_open, original_getenv = io.open, os.getenv
	local available
	rawset(io, "open", function(path)
		if path == available then
			return { close = function() end }
		end
		return nil
	end)
	rawset(os, "getenv", function(name) return name == "PATH" and "/fixture/bin:/other/bin" or original_getenv(name) end)
	local ok, err = pcall(function()
		status = tailnet("alpha")
		for _, path in ipairs({
			"/fixture/bin/tailscale",
			"/opt/homebrew/bin/tailscale",
			"/usr/local/bin/tailscale",
			"/Applications/Tailscale.app/Contents/MacOS/Tailscale",
		}) do
			available = path
			hosts.get_choices({ known_hosts_files = {} })
			equal(runs[#runs][5], path)
		end
		available = nil
		local before = #runs
		local _, meta = hosts.get_choices({ known_hosts_files = {} })
		equal(#runs, before)
		assert(meta.status:find("binary not found", 1, true))
	end)
	io.open, os.getenv = original_open, original_getenv
	assert(ok, err)
end)

test("unsupported native IPv6 literal transport is explicit and never misconnects", function()
	fixture("[2001:db8::1]:2200 ssh-ed25519 AAAA\n", function(path)
		hosts.switch_host({ tailscale = false, known_hosts_files = { path } })(window, {})
		assert(picker().choices[1].label:find("IPv6: use SSH alias", 1, true))
		picker().action(window, {}, picker().choices[1].id, nil)
		equal(#spawns, 0)
		assert(toasts[#toasts]:find("IPv6", 1, true))
	end)
end)

test("alias dedupe never normalizes away distinct configured names", function()
	aliases =
		{ First = { hostname = "server.example", user = "same" }, first = { hostname = "server.example", user = "same" } }
	local choices, meta = hosts.get_choices({ tailscale = false, known_hosts_files = {} })
	equal(#choices, 2)
	assert(targets(meta).First and targets(meta).first)
end)

test("malformed tailnet identity leaves static choices available", function()
	for _, damage in ipairs({
		function() status.CurrentTailnet.MagicDNSSuffix = {} end,
		function() status.CurrentTailnet.Name = "" end,
		function() status.Self.ID = {} end,
		function() status.Self.UserID = {} end,
	}) do
		status = tailnet("alpha")
		aliases = { Work = {} }
		damage()
		local choices, meta = hosts.get_choices(opts)
		equal(#choices, 1)
		assert(meta.status:find("missing identity", 1, true))
	end
end)

test("public SSH planning preserves aliases without launching", function()
	local argv = assert(hosts.launch_args({ target = "Work", source = "alias" }))
	equal(table.concat(argv, " | "), wezterm.executable_dir .. "/wezterm | ssh | -- | Work")
	equal(#spawns, 0)
	equal(#runs, 0)
end)

test("public planning validates serialized rows instead of trusting derived fields", function()
	for _, row in ipairs({
		{ target = "host;id", source = "alias", host = "safe", port = 22 },
		{ target = "safe", source = "unknown" },
		{ target = "safe", source = "tailscale" },
		{},
		false,
		"host",
	}) do
		local ok, argv, err = pcall(hosts.launch_args, row, opts)
		assert(ok and argv == nil and type(err) == "string", "invalid rows must return nil,error")
	end
	local argv =
		assert(hosts.launch_args({ target = "Server.EXAMPLE:22", source = "known-host", host = "evil", port = 99 }))
	equal(argv[4], "HostName=server.example")
	equal(argv[#argv], "Server.EXAMPLE:22", "explicit default port must not be doubled")
	status = tailnet("alpha")
	local _, meta = hosts.get_choices(opts)
	local row = targets(meta).desktop
	row.host, row.port = nil, nil
	assert(hosts.launch_args(row, opts), "minimal serialized tailnet row remains valid")
	row.target = "other.example"
	local rejected, err = hosts.launch_args(row, opts)
	assert(not rejected and err, "peer identity cannot authorize a different target")
	equal(#spawns, 0)
end)

test("manual SSH fallback preserves typed aliases users and explicit ports", function()
	aliases = { Work = { hostname = "redirected.example", port = "2222", proxycommand = "trusted config" } }
	for _, input in ipairs({ "Work", "Alice@Work", "Alice@Work:22", "Alice@Work:02200" }) do
		local argv = assert(hosts.launch_args({ input = "  " .. input .. "\t" }))
		equal(table.concat(argv, " | "), wezterm.executable_dir .. "/wezterm | ssh | -- | " .. input)
	end
	for _, input in ipairs({ "Bob@192.0.2.1", "NEW.example:22", "NEW.example:0022" }) do
		local argv = assert(hosts.launch_args({ input = input }))
		equal(argv[3], "-o")
		equal(argv[6], "ProxyCommand=none")
		equal(argv[#argv], input .. (not input:find(":", 1, true) and ":22" or ""))
	end
	for _, input in ipairs({
		"",
		" ",
		"a b",
		"a\nb",
		"a;id",
		"-option",
		"user@@host",
		"a:0",
		"a:65536",
		"a/command",
		"$(id)",
		"a:abc",
		"999.1.1.1",
		"[::1]",
		"::1",
	}) do
		local argv, err = hosts.launch_args({ input = input })
		assert(not argv and type(err) == "string", "reject " .. input)
		if input:find("::", 1, true) then
			assert(err:find("IPv6", 1, true))
		end
	end
	local argv, err = hosts.launch_args({ input = "Work", target = "elsewhere", source = "alias" })
	assert(not argv and err, "ambiguous selection is rejected")
	equal(#spawns, 0)
	equal(#runs, 0, "typed input never discovers tailnets")
end)

print("PASS hosts: " .. count .. " tests (" .. _VERSION .. ")")
