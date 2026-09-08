-- Dynamic native SSH discovery. Never probes a remote or changes tailnet accounts.
local wezterm = require("wezterm")
local M = {}

local function host_key(host)
	if host:find(":", 1, true) then
		if host:find("[^%x:]") or host:find(":::", 1, true) then
			return nil
		end
		local left, right = host:match("^(.-)::(.-)$")
		if right and right:find("::", 1, true) then
			return nil
		end
		local groups = {}
		for group in host:gmatch("[^:]+") do
			if #group > 4 then
				return nil
			end
			groups[#groups + 1] = string.format("%x", tonumber(group, 16))
		end
		if (not left and (#groups ~= 8 or host:match("^:") or host:match(":$"))) or (left and #groups >= 8) then
			return nil
		end
		if left then
			local before = 0
			for _ in left:gmatch("[^:]+") do
				before = before + 1
			end
			for _ = #groups + 1, 8 do
				table.insert(groups, before + 1, "0")
			end
		end
		return table.concat(groups, ":")
	end
	host = host:lower():gsub("%.$", "")
	if host == "" or host:find("..", 1, true) then
		return nil
	end
	for label in host:gmatch("[^.]+") do
		if not label:match("^[%w_][%w_%-]*$") or label:match("%-$") then
			return nil
		end
	end
	if host:match("^[%d.]+$") then
		local n = 0
		for octet in host:gmatch("[^.]+") do
			if tonumber(octet) > 255 then
				return nil
			end
			n = n + 1
		end
		if n ~= 4 then
			return nil
		end
	end
	return host
end

local function endpoint(value)
	if type(value) ~= "string" or value == "" or value:find("[^%w_.:@%[%]%-]") or value:sub(1, 1) == "-" then
		return nil
	end
	local user, address = value:match("^([%w_.%-]+)@(.+)$")
	address = address or value
	local host, port
	if address:sub(1, 1) == "[" then
		host, port = address:match("^%[([%w_.:%-]+)%]:(%d+)$")
		host = host or address:match("^%[([%w_.:%-]+)%]$")
		if not host then
			return nil
		end
	else
		host, port = address:match("^([%w_.%-]+):(%d+)$")
		host = host or address:match("^([%w_.%-]+)$")
		if not host or not host:match("^[%w_]") then
			return nil
		end
	end
	port = port and tonumber(port) or 22
	if port < 1 or port > 65535 then
		return nil
	end
	local canonical = host_key(host)
	if not canonical or (user and user:sub(1, 1) == "-") then
		return nil
	end
	local display = host:find(":", 1, true) and ("[" .. host .. "]") or host
	return {
		target = (user and (user .. "@") or "") .. display .. (port ~= 22 and (":" .. port) or ""),
		key = canonical .. ":" .. port,
		host = canonical,
		port = port,
		user = user,
	}
end

local function tailscale_path(opts)
	if opts.tailscale_path then
		return opts.tailscale_path
	end
	local paths = {}
	for dir in (os.getenv("PATH") or ""):gmatch("[^:]+") do
		paths[#paths + 1] = dir .. "/tailscale"
	end
	for _, path in ipairs({
		"/opt/homebrew/bin/tailscale",
		"/usr/local/bin/tailscale",
		"/Applications/Tailscale.app/Contents/MacOS/Tailscale",
	}) do
		paths[#paths + 1] = path
	end
	for _, path in ipairs(paths) do
		local file = io.open(path, "r")
		if file then
			file:close()
			return path
		end
	end
end

local function tailnet_rows(opts)
	if opts.tailscale == false then
		return {}, "Tailscale disabled"
	end
	local path = tailscale_path(opts)
	if not path then
		return {}, "Tailscale unavailable (binary not found)"
	end
	local ok, success, stdout = pcall(wezterm.run_child_process, {
		"/usr/bin/perl",
		"-e",
		"alarm shift; exec @ARGV; die qq(exec failed: $!);",
		"3",
		path,
		"status",
		"--json",
	})
	if not ok or not success then
		return {}, "Tailscale unavailable (status failed or timed out)"
	end
	local parsed, data = pcall(wezterm.json_parse, stdout)
	if not parsed or type(data) ~= "table" then
		return {}, "Tailscale unavailable (invalid JSON)"
	end
	if data.BackendState ~= "Running" then
		return {}, "Tailscale not Running"
	end
	local net, self = data.CurrentTailnet, data.Self
	if
		type(net) ~= "table"
		or type(net.Name) ~= "string"
		or net.Name == ""
		or (net.MagicDNSSuffix ~= nil and type(net.MagicDNSSuffix) ~= "string")
		or type(self) ~= "table"
		or type(self.ID) ~= "string"
		or self.ID == ""
		or (type(self.UserID) ~= "number" and type(self.UserID) ~= "string")
	then
		return {}, "Tailscale unavailable (missing identity)"
	end
	local identity = table.concat({ net.Name, net.MagicDNSSuffix or "", tostring(self.ID), tostring(self.UserID) }, "\0")
	local rows = {}
	for id, peer in pairs(type(data.Peer) == "table" and data.Peer or {}) do
		if type(peer) == "table" and not peer.Location and peer.ID ~= self.ID then
			local dns = type(peer.DNSName) == "string" and peer.DNSName:gsub("%.$", "") or ""
			local row = dns:find("%.") and not dns:find("[@:]") and endpoint(dns) or nil
			if not row then
				for _, ip in ipairs(type(peer.TailscaleIPs) == "table" and peer.TailscaleIPs or {}) do
					if type(ip) == "string" and ip:match("^[%d.]+$") then
						row = endpoint(ip)
					end
					if row then
						break
					end
				end
			end
			if row then
				row.address_keys = { row.key }
				-- Use the current MagicDNS suffix only; arbitrary FQDNs stay intact.
				local suffix = type(net.MagicDNSSuffix) == "string" and net.MagicDNSSuffix:lower():gsub("%.$", "") or ""
				local ending = "." .. suffix
				if suffix ~= "" and row.host:sub(-#ending) == ending then
					local short = row.host:sub(1, -#ending - 1)
					if short ~= "" and not short:find("%.") then
						row.target = short
						row.address_keys[#row.address_keys + 1] = short .. ":22"
					end
				end
				for _, ip in ipairs(type(peer.TailscaleIPs) == "table" and peer.TailscaleIPs or {}) do
					local address = endpoint(ip)
					if address then
						row.address_keys[#row.address_keys + 1] = address.key
					end
				end
				row.source, row.identity, row.peer_id = "tailscale", identity, peer.ID or id
				row.label = row.target
					.. " ["
					.. (peer.Online == true and "online" or "offline")
					.. "; "
					.. tostring(peer.OS or "unknown OS"):gsub("%c", "")
					.. "]"
				rows[#rows + 1] = row
			end
		end
	end
	return rows,
		"Tailscale: "
			.. net.Name:gsub("%c", "")
			.. (#rows == 0 and " (no eligible peers; SSH not probed)" or " (SSH not probed)"),
		net.Name
end

function M.get_choices(opts)
	opts = opts or {}
	local rows, seen = {}, {}
	local function add(value, source, config)
		local row = endpoint(value)
		if not row then
			return
		end
		---@type table?
		local resolved = row
		if source == "alias" and type(config) == "table" and config.hostname then
			local host = config.hostname
			if host:find(":", 1, true) and host:sub(1, 1) ~= "[" then
				host = "[" .. host .. "]"
			end
			resolved = endpoint(host .. (config.port and (":" .. config.port) or ""))
		end
		if source == "alias" or not seen[row.key] then
			row.source = source
			if source == "alias" then
				row.target = value -- Native CLI rereads User/Port/IdentityFile for this alias.
			end
			if resolved then -- Invalid HostName must not claim the alias spelling.
				seen[resolved.key] = true
			end
			rows[#rows + 1] = row
		end
	end
	local ok, aliases = pcall(wezterm.enumerate_ssh_hosts)
	if ok and type(aliases) == "table" then
		local names = {}
		for name in pairs(aliases) do
			names[#names + 1] = name
		end
		table.sort(names)
		for _, name in ipairs(names) do
			add(name, "alias", aliases[name])
		end
	end
	local peers, status, tailnet = tailnet_rows(opts)
	if not ok or type(aliases) ~= "table" then
		status = status .. "; SSH config unavailable"
	end
	for _, row in ipairs(peers) do
		local duplicate = false
		for _, key in ipairs(row.address_keys) do
			if seen[key] then
				duplicate = true
			end
		end
		for _, key in ipairs(row.address_keys) do
			seen[key] = true
		end
		if not duplicate then
			rows[#rows + 1] = row
		end
	end
	for _, path in ipairs(opts.known_hosts_files or { wezterm.home_dir .. "/.ssh/known_hosts" }) do
		local file = io.open(path, "r")
		if file then
			local read_ok = pcall(function()
				for line in file:lines() do
					local field = line:match("^%s*([^%s]+)%s+%S+%s+%S+")
					if field and not field:match("^[#@|]") then
						for value in field:gmatch("[^,]+") do
							add(value, "known-host")
						end
					end
				end
			end)
			file:close()
			if not read_ok then
				status = status .. "; known_hosts unreadable"
			end
		end
	end
	table.sort(rows, function(a, b) return a.target < b.target end)
	local choices, meta = {}, { status = status, tailnet = tailnet, targets = {} }
	for index, row in ipairs(rows) do
		local id = tostring(index)
		local label = row.label or (row.target .. " [" .. row.source .. "]")
		if row.host:find(":", 1, true) then
			label = label .. " [IPv6: use SSH alias]"
		end
		choices[#choices + 1] = { id = id, label = label }
		meta.targets[id] = row
	end
	return choices, meta
end

-- Plan only: callers decide when to launch the native executable.
function M.launch_args(row, opts)
	opts = opts or {}
	if type(row) == "table" and row.input ~= nil then
		if type(row.input) ~= "string" or row.target ~= nil or row.source ~= nil then
			return nil, "Invalid SSH selection."
		end
		local input = row.input:match("^%s*(.-)%s*$")
		if input:match(":.*:") then
			return nil, "Native IPv6 literals unsupported; use an SSH-config alias."
		end
		if not endpoint(input) then
			return nil, "Invalid SSH target; use [user@]host[:port]."
		end
		local ok, aliases = pcall(wezterm.enumerate_ssh_hosts)
		if not ok or type(aliases) ~= "table" then
			return nil, "SSH config unavailable; cannot resolve typed alias."
		end
		local name = input:gsub("^.-@", ""):gsub(":%d+$", "")
		row = { target = input, source = aliases[name] ~= nil and "alias" or "known-host" }
	end
	if type(row) ~= "table" or (row.source ~= "alias" and row.source ~= "known-host" and row.source ~= "tailscale") then
		return nil, "Invalid SSH selection."
	end
	local parsed = endpoint(row.target)
	if not parsed then
		return nil, "Invalid SSH target."
	end
	-- c7f4b081 cannot safely represent literal IPv6 in remote_address.
	if parsed.host:find(":", 1, true) then
		return nil, "Native IPv6 literals unsupported; use an SSH-config alias."
	end
	if row.source == "tailscale" then
		local current, valid = tailnet_rows(opts), false
		for _, peer in ipairs(current) do
			if
				peer.identity == row.identity
				and peer.peer_id == row.peer_id
				and peer.key == row.key
				and peer.target == row.target
			then
				valid = true
				-- Match User against the short target, but pin transport to the
				-- freshly verified FQDN/IP rather than trusting serialized fields.
				parsed.host = peer.host
			end
		end
		if not valid then
			return nil, "Tailnet or peer changed or unavailable; reopen the picker."
		end
	end
	local target = row.target .. (row.source ~= "alias" and not row.target:match(":%d+$") and ":22" or "")
	local argv = { wezterm.executable_dir .. "/wezterm", "ssh" }
	if row.source ~= "alias" then
		table.insert(argv, "-o")
		table.insert(argv, "HostName=" .. parsed.host)
		table.insert(argv, "-o")
		table.insert(argv, "ProxyCommand=none")
	end
	table.insert(argv, "--")
	table.insert(argv, target)
	return argv
end

function M.switch_host(opts)
	opts = opts or {}
	return wezterm.action_callback(function(window, pane)
		local choices, meta = M.get_choices(opts)
		window:perform_action(
			wezterm.action.InputSelector({
				title = "SSH hosts — " .. meta.status,
				description = "Select an SSH host",
				fuzzy_description = "SSH hosts: ",
				fuzzy = true,
				choices = choices,
				action = wezterm.action_callback(function(_, _, id)
					local row = id and meta.targets[id]
					if not row then
						return
					end
					local argv, err = M.launch_args(row, opts)
					if not argv then
						window:toast_notification("SSH hosts", tostring(err), nil, 5000)
						return
					end
					local started = pcall(wezterm.background_child_process, argv)
					if not started then
						window:toast_notification("SSH hosts", "Could not start native WezTerm SSH.", nil, 5000)
					end
				end),
			}),
			pane
		)
	end)
end

return M
