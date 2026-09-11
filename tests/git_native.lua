-- Native constructors and emitted callbacks; never launch a GUI or real TUI.
local wezterm = require("wezterm")
local ok, config = xpcall(function()
	local root = os.getenv("WEZMACS_SMOKE_ROOT") or "."
	package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
	wezterm.run_child_process = function() error("unexpected process") end
	wezterm.background_child_process = function() error("unexpected background process") end
	package.preload["wezmacs.modules.git.runtime"] = function()
		return {
			label = function(s) return tostring(s):gsub("%c", "?") end,
			run = function(name) return "version", "/fake/" .. name end,
		}
	end
	package.preload["wezmacs.modules.git.repository"] = function()
		return {
			resolve = function(cwd) return { cwd = cwd, git = "/fake/git" } end,
			revisions = function() return { { id = "refs/heads/main", label = "main" } } end,
			diff_args = function()
				return { "/fake/git", "--no-pager", "diff", "--no-ext-diff", "--no-textconv", string.rep("a", 40), "--" }
			end,
			worktrees = function() return { { path = "/test/tree", detached = true } } end,
			validate_worktree = function() return { path = "/test/tree", detached = true } end,
		}
	end
	wezterm.mux.get_workspace_names = function() return {} end
	local git = require("wezmacs.modules.git.actions")
	local actions, notices = {}, {}
	local win, pane = {}, {}
	function pane:get_domain_name() return "local" end
	function pane:get_current_working_dir() return wezterm.url.parse("file:///test/repo") end
	function win:perform_action(action) actions[#actions + 1] = action end
	function win:toast_notification(_, text) notices[#notices + 1] = text end
	function win:active_workspace() return "old" end
	local opts = { shell = "/bin/sh", direnv = false }
	local function emit(action, ...) wezterm.emit(action.EmitEvent, win, pane, ...) end
	emit(git.lazygit(opts))
	assert(#notices == 0, table.concat(notices, "\n"))
	assert(actions[1].SplitPane.size.Percent == 50, "real native SplitPane size")
	emit(git.lazygit(opts, "tab"))
	assert(actions[2].SpawnCommandInNewTab.args[1] == "/bin/sh")
	emit(git.compare(opts))
	local selector = actions[3].InputSelector
	assert(selector.fuzzy_description == "Git revisions: ")
	emit(selector.action, nil)
	assert(#actions == 3)
	emit(selector.action, "refs/heads/main")
	local modes = actions[4].InputSelector
	assert(#modes.choices == 3)
	emit(modes.action, "head")
	assert(actions[5].SplitPane.command.args[3]:find("/fake/delta", 1, true))
	emit(selector.action, selector.choices[2].id)
	assert(actions[6].PromptInputLine)
	emit(git.switch_worktree(opts))
	emit(actions[7].InputSelector.action, "/test/tree")
	assert(actions[8].SwitchToWorkspace.spawn.cwd == "/test/tree")
	assert(#notices == 0, table.concat(notices, "\n"))
	local built = wezterm.config_builder()
	---@cast built WezmacsConfigBuilder
	built:set_strict_mode(true)
	local keys = {}
	for index, action in ipairs(actions) do
		keys[#keys + 1] = { key = "F" .. index, mods = "CTRL|SHIFT|ALT|SUPER", action = action }
	end
	keys[#keys + 1] = {
		key = "F24",
		mods = "CTRL|SHIFT|ALT|SUPER",
		action = wezterm.action.SendString("__WEZMACS_REGRESSION_VALIDATED__"),
	}
	built.keys = keys
	local validated = wezterm.config_builder()
	---@cast validated WezmacsConfigBuilder
	validated:set_strict_mode(true)
	for key, value in pairs(built) do
		validated[key] = value
	end
	print("PASS native Git actions")
	return validated
end, tostring)
if not ok then
	io.stderr:write(tostring(config), "\n")
	os.exit(1)
end
return config
