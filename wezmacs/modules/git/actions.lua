-- Native callbacks only: no local queries until a known-local pane invokes one.
local wezterm = require("wezterm")
local repository = require("wezmacs.modules.git.repository")
local runtime = require("wezmacs.modules.git.runtime")
local M = {}
local function notify(window, message)
	pcall(function() window:toast_notification("Git", runtime.label(message), nil, 6000) end)
end
local function callback(fn)
	return wezterm.action_callback(function(window, pane, ...)
		local ok, err = pcall(fn, window, pane, ...)
		if not ok then
			notify(window, err)
		end
	end)
end
local function context(pane, opts)
	local ok, cwd = pcall(function()
		assert(pane:get_domain_name() == "local", "Git actions require a local pane domain")
		local uri = assert(pane:get_current_working_dir(), "Pane has no working-directory URI")
		local host = uri.host
		assert(
			host == nil or host == "" or host == "localhost" or host == wezterm.hostname(),
			"Git actions require a local cwd hostname"
		)
		assert(
			type(uri.file_path) == "string" and uri.file_path:sub(1, 1) == "/",
			"Pane has no absolute local working directory"
		)
		return uri.file_path
	end)
	if not ok then
		return nil, cwd
	end
	return repository.resolve(cwd, opts)
end
local launcher = require("wezmacs.modules.git.launch")
local launch = launcher.run
local tool_args = { lazygit = {}, gh = { "dash" }, broot = { "-ghc", ":gs" }, lazyjj = {} }
function M.tool(name, opts, placement)
	assert(tool_args[name], "Unknown Git terminal tool")
	opts = launcher.validate(opts, placement)
	return callback(function(window, pane)
		local repo, err = context(pane, opts)
		if not repo then
			return notify(window, err)
		end
		local output, bin, tool_err = runtime.run(name, opts[name .. "_path"], { "--version" })
		if not output then
			return notify(window, tool_err)
		end
		local argv = { bin }
		for _, value in ipairs(tool_args[name]) do
			argv[#argv + 1] = value
		end
		launch(window, pane, repo, opts, placement, argv)
	end)
end
function M.lazygit(opts, placement) return M.tool("lazygit", opts, placement) end
local modes = {
	working_tree = "Revision → working tree (including index)",
	head = "Revision → HEAD (committed only)",
	merge_base = "Merge base with revision → HEAD",
}
local function choose(window, pane, title, choices, accept)
	local known = {}
	for _, choice in ipairs(choices) do
		known[choice.id] = true
		choice.label = runtime.label(choice.label)
	end
	window:perform_action(
		wezterm.action.InputSelector({
			title = title,
			description = title,
			fuzzy_description = title .. ": ",
			fuzzy = true,
			choices = choices,
			action = callback(function(win, target, id)
				if id and known[id] then
					accept(win, target, id)
				end
			end),
		}),
		pane
	)
end
local function comparison(window, pane, repo, opts, placement, revision)
	local choices, preferred = {}, opts.comparison_mode or "working_tree"
	choices[1] = { id = preferred, label = modes[preferred] .. " (default)" }
	for _, mode in ipairs({ "working_tree", "head", "merge_base" }) do
		if mode ~= preferred then
			choices[#choices + 1] = { id = mode, label = modes[mode] }
		end
	end
	choose(window, pane, "Compare mode", choices, function(win, target, mode)
		local current, err = context(target, opts)
		if not current then
			return notify(win, err)
		end
		if current.cwd ~= repo.cwd then
			return notify(win, "Pane repository changed; reopen comparison")
		end
		local argv, diff_err = repository.diff_args(current, revision, mode)
		if not argv then
			return notify(win, diff_err)
		end
		require("wezmacs.modules.git.launch").diff(win, target, current, opts, placement, argv)
	end)
end
function M.compare(opts, placement)
	opts = launcher.validate(opts, placement)
	return callback(function(window, pane)
		local repo, err = context(pane, opts)
		if not repo then
			return notify(window, err)
		end
		local choices, refs_err = repository.revisions(repo, opts)
		if not choices then
			return notify(window, refs_err)
		end
		local prompt_id = "wezmacs:enter-revision"
		choices[#choices + 1] = { id = prompt_id, label = "Enter revision…" }
		choose(window, pane, "Git revisions", choices, function(win, target, id)
			if id == prompt_id then
				win:perform_action(
					wezterm.action.PromptInputLine({
						description = "Enter Git revision",
						action = callback(function(w, p, revision)
							if revision and revision ~= "" then
								comparison(w, p, repo, opts, placement, revision)
							end
						end),
					}),
					target
				)
			else
				comparison(win, target, repo, opts, placement, id)
			end
		end)
	end)
end
local function absolute(path)
	if path == "~" then
		path = wezterm.home_dir
	elseif path:sub(1, 2) == "~/" then
		path = wezterm.home_dir .. path:sub(2)
	end
	local trimmed = path:gsub("/+$", "")
	return trimmed == "" and "/" or trimmed
end
local function display(path)
	local home = wezterm.home_dir
	if path == home then
		return "~"
	end
	if path:sub(1, #home + 1) == home .. "/" then
		return "~" .. path:sub(#home + 1)
	end
	return path
end
function M.switch_worktree(opts)
	opts = launcher.validate(opts)
	return callback(function(window, pane)
		local repo, err = context(pane, opts)
		if not repo then
			return notify(window, err)
		end
		local rows, list_err = repository.worktrees(repo)
		if not rows then
			return notify(window, list_err)
		end
		local choices, running = {}, {}
		for _, name in ipairs(wezterm.mux.get_workspace_names()) do
			running[absolute(name)] = true
		end
		for _, row in ipairs(rows) do
			local revision = row.branch or (row.detached and ("detached " .. (row.head or ""):sub(1, 8)) or "bare")
			local label = display(row.path) .. "  [" .. revision .. "]"
			if absolute(row.path) == absolute(repo.cwd) then
				label = label .. " [current]"
			end
			if running[absolute(row.path)] then
				label = label .. " [open]"
			end
			if row.locked then
				label = label .. " [locked: " .. row.locked .. "]"
			end
			if row.prunable then
				label = label .. " [prunable: " .. row.prunable .. "]"
			end
			choices[#choices + 1] = { id = row.path, label = label }
		end
		choose(window, pane, "Git worktrees", choices, function(win, target, path)
			local current, current_err = context(target, opts)
			if not current then
				return notify(win, current_err)
			end
			if current.cwd ~= repo.cwd then
				return notify(win, "Pane repository changed; reopen worktrees")
			end
			local row, validate_err = repository.validate_worktree(current, path)
			if not row then
				return notify(win, validate_err)
			end
			local name, live = display(path), false
			for _, existing in ipairs(wezterm.mux.get_workspace_names()) do
				if absolute(existing) == absolute(path) then
					name, live = existing, true
					break
				end
			end
			local previous = win:active_workspace()
			if previous == name then
				return
			end
			local command = { name = name }
			if not live then
				command.spawn = { cwd = path, domain = "CurrentPaneDomain" }
			end
			win:perform_action(wezterm.action.SwitchToWorkspace(command), target)
			wezterm.GLOBAL.wezmacs_workspace_previous = previous
		end)
	end)
end
return M
