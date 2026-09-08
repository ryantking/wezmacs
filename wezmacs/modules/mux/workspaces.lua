-- Local POSIX workspace discovery; no I/O at config load or action construction.
-- opts.root defaults to ~/Workspaces (absolute or ~/ path); traversal is fixed at
-- two levels. opts.zoxide_path is one executable, never a shell command. Default
-- "zoxide" tries PATH, macOS Homebrew paths, then ~/.local/bin; explicit overrides
-- are authoritative. Directory reads are protected and cached per collection.
-- Dedup expands ~/ and strips trailing /, but does not resolve symlinks or ../.
-- Zoxide's line-delimited output cannot represent paths containing newlines.
local wezterm = require("wezterm")
local M = {}

local function absolute(path)
	if path == "~" then
		path = wezterm.home_dir
	elseif path:sub(1, 2) == "~/" then
		path = wezterm.home_dir .. path:sub(2)
	end
	if path:sub(1, 1) ~= "/" then
		return path
	end
	local trimmed = path:gsub("/+$", "")
	return trimmed == "" and "/" or trimmed
end

local function display(path)
	if path == wezterm.home_dir then
		return "~"
	end
	if path:sub(1, #wezterm.home_dir + 1) == wezterm.home_dir .. "/" then
		return "~" .. path:sub(#wezterm.home_dir + 1)
	end
	return path
end

-- Scan-only exclusions: hidden entries plus common dependency/build caches.
local skip = { node_modules = true, target = true, build = true, dist = true, __pycache__ = true, coverage = true }

local function query(opts)
	local binaries = { opts.zoxide_path or "zoxide" }
	if binaries[1] == "zoxide" then
		if wezterm.target_triple:find("apple", 1, true) then
			binaries[#binaries + 1] = "/opt/homebrew/bin/zoxide"
			binaries[#binaries + 1] = "/usr/local/bin/zoxide"
		end
		binaries[#binaries + 1] = wezterm.home_dir .. "/.local/bin/zoxide"
	end
	for _, bin in ipairs(binaries) do
		local ok, success, stdout = pcall(wezterm.run_child_process, { bin, "query", "-l" })
		-- Spawn errors raise; a nonzero query can simply mean an empty database.
		if ok then
			return success and stdout or "", bin
		end
	end
	return ""
end

local function collect(opts, live_names)
	opts = opts or {}
	local choices, seen, listings, paths_by_id = {}, {}, {}, {}
	local function read(path)
		if listings[path] == nil then
			local ok, entries = pcall(wezterm.read_dir, path)
			listings[path] = ok and entries or false
		end
		return listings[path]
	end
	local function add(path)
		path = absolute(path)
		if not seen[path] and path:sub(1, 1) == "/" and read(path) then
			choices[#choices + 1] = { id = path, label = display(path) }
			paths_by_id[path] = path
			seen[path] = true
		end
	end
	for _, name in ipairs(live_names or wezterm.mux.get_workspace_names()) do
		local key = absolute(name)
		if not seen[key] then
			choices[#choices + 1] = { id = name, label = name }
			seen[key] = true
		end
	end
	local stdout, bin = query(opts)
	for path in stdout:gmatch("[^\r\n]+") do
		add(path)
	end
	local paths = {}
	local function scan(parent, depth)
		for _, path in ipairs(read(parent) or {}) do
			local name = path:match("([^/]+)$")
			if name and name:sub(1, 1) ~= "." and not skip[name] and read(path) then
				paths[#paths + 1] = path
				if depth < 2 then
					scan(path, depth + 1)
				end
			end
		end
	end
	scan(absolute(opts.root or (wezterm.home_dir .. "/Workspaces")), 1)
	table.sort(paths)
	for _, path in ipairs(paths) do
		add(path)
	end
	return choices, paths_by_id, bin
end

-- Read-only collection: { { id = raw_workspace_or_absolute_path, label = text } }.
-- Order: live mux names, zoxide rank, sorted scan. Only directory candidates are
-- checked for readability; live named/remote workspaces do not require local dirs.
-- A headless caller can supply live_names; {} deliberately means no live workspaces.
function M.get_choices(opts, live_names)
	local choices = collect(opts, live_names)
	return choices
end

local function switch(window, pane, command)
	local current = window:active_workspace()
	if current == command.name then
		return
	end
	window:perform_action(wezterm.action.SwitchToWorkspace(command), pane)
	wezterm.GLOBAL.wezmacs_workspace_previous = current
end

-- Returns a native action callback; selection ignores presentation labels.
function M.switch_workspace(opts)
	return wezterm.action_callback(function(window, pane)
		local choices, paths, bin = collect(opts)
		local current, running = window:active_workspace(), {}
		for _, name in ipairs(wezterm.mux.get_workspace_names()) do
			running[name] = true
		end
		local current_index
		for index, choice in ipairs(choices) do
			if running[choice.id] then
				choice.label = choice.label .. (choice.id == current and " [current]" or " [running]")
				if choice.id == current then
					current_index = index
				end
			end
		end
		if current_index then
			table.insert(choices, 1, table.remove(choices, current_index))
		end
		local offered = {}
		for _, choice in ipairs(choices) do
			offered[choice.id] = true
		end
		window:perform_action(
			wezterm.action.InputSelector({
				title = "Choose Workspace",
				description = "Select a workspace",
				fuzzy_description = "Workspaces: ",
				fuzzy = true,
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id or not offered[id] then
						return
					end
					for _, name in ipairs(wezterm.mux.get_workspace_names()) do
						if id == name or absolute(id) == absolute(name) then
							switch(inner_window, inner_pane, { name = name })
							return
						end
					end
					local path = paths[id]
					if path and pcall(wezterm.read_dir, path) then
						switch(inner_window, inner_pane, {
							name = display(path),
							spawn = { cwd = path, domain = { DomainName = "local" } },
						})
						if bin then
							pcall(wezterm.run_child_process, { bin, "add", "--", path })
						end
					end
				end),
			}),
			pane
		)
	end)
end

-- History follows the GUI client's workspace across config reloads. window_id()
-- identifies the represented mux window and changes when the GUI is repurposed.
function M.switch_to_prev_workspace()
	return wezterm.action_callback(function(window, pane)
		local previous = wezterm.GLOBAL.wezmacs_workspace_previous
		if not previous then
			return
		end
		for _, name in ipairs(wezterm.mux.get_workspace_names()) do
			if name == previous then
				switch(window, pane, { name = name })
				return
			end
		end
	end)
end

return M
