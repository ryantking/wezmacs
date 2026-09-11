package.path = "./?.lua;./?/init.lua;" .. package.path
local actions, notices, queries = {}, {}, {}
local native = { GLOBAL = {}, home_dir = "/home/test", hostname = function() return "local-host" end }
native.action = setmetatable({}, {
	__index = function(_, key)
		return function(value) return { [key] = value } end
	end,
})
native.action_callback = function(fn) return fn end
native.mux = { get_workspace_names = function() return {} end }
package.loaded.wezterm = native
package.loaded.wezmacs = { config = { shell = "/bin/sh" } }
local runtime, unavailable = {}, {}
function runtime.label(s) return tostring(s):gsub("%c", "?") end
function runtime.run(name, override, args)
	queries[#queries + 1] = { name, override, args }
	if unavailable[name] then
		return nil, nil, name .. " unavailable"
	end
	return "version", override or ("/fake/" .. name)
end
package.loaded["wezmacs.modules.git.runtime"] = runtime
local repo = {}
function repo.resolve(cwd)
	queries[#queries + 1] = cwd
	return { cwd = cwd, git = "/fake/git" }
end
package.loaded["wezmacs.modules.git.repository"] = repo
local pane = { host = "", cwd = "/repo/a '$(touch nope)", domain = "local" }
function pane:get_domain_name() return self.domain end
function pane:get_current_working_dir() return self.cwd and { file_path = self.cwd, host = self.host } end
local win = {}
function win:perform_action(action) actions[#actions + 1] = action end
function win:toast_notification(_, message) notices[#notices + 1] = message end
local function reset()
	actions, notices, queries = {}, {}, {}
end
local git = require("wezmacs.modules.git.actions")
local open = git.lazygit({ direnv = false, shell = "/bin/sh" })
assert(#queries == 0, "construction is query-free")
open(win, pane)
local split = assert(actions[1].SplitPane, "native split required")
assert(split.direction == "Right" and split.size.Percent == 50)
assert(split.command.cwd == pane.cwd and split.command.domain == "CurrentPaneDomain")
assert(split.command.args[1] == "/bin/sh" and split.command.args[2] == "-lc")
assert(split.command.args[3] == "exec '/fake/lazygit'", "TUI exits with no leftover shell")
for _, bad in ipairs({
	{ domain = "ssh", host = "", cwd = "/repo" },
	{ domain = "local", host = "remote", cwd = "/repo" },
	{ host = "", cwd = "/repo" },
	{ domain = "local", host = "" },
}) do
	reset()
	open(
		win,
		setmetatable(
			bad,
			{ __index = { get_domain_name = pane.get_domain_name, get_current_working_dir = pane.get_current_working_dir } }
		)
	)
	assert(#queries == 0 and #actions == 0 and #notices == 1, "unknown/remote context denied before query")
end
reset()
git.lazygit({ shell = "/bin/sh" })(win, pane)
assert(
	actions[1].SplitPane.command.args[3] == "exec '/fake/direnv' 'exec' '/repo/a '\\''$(touch nope)' '/fake/lazygit'",
	"auto direnv uses literal cwd"
)
unavailable.direnv = true
reset()
git.lazygit({ direnv = true })(win, pane)
assert(#actions == 0 and notices[1]:find("direnv unavailable", 1, true))
reset()
git.tool("gh", { direnv = "auto" }, "tab")(win, pane)
assert(actions[1].SpawnCommandInNewTab.args[3] == "exec '/fake/gh' 'dash'")
unavailable.direnv = false
local selected_mode, selected_ref
function repo.revisions() return { { id = "refs/heads/topic", label = "topic\27[31m" } } end
function repo.diff_args(_, ref, mode)
	selected_ref, selected_mode = ref, mode
	if ref == "stale" then
		return nil, "Revision no longer exists"
	end
	return { "/fake/git", "--no-pager", "diff", "--no-ext-diff", "--no-textconv", string.rep("a", 40), "--" }
end
reset()
local compare = git.compare({ direnv = false, shell = "/bin/sh" }, "tab")
assert(#queries == 0)
compare(win, pane)
local refs = assert(actions[1].InputSelector)
assert(refs.fuzzy and #refs.choices == 2 and not refs.choices[1].label:find("\27", 1, true))
refs.action(win, pane, nil)
refs.action(win, pane, "unknown")
assert(#actions == 1, "cancel/unknown ids cannot launch")
refs.action(win, pane, "refs/heads/topic", "untrusted label")
local modes = assert(actions[2].InputSelector)
assert(#modes.choices == 3 and modes.choices[1].id == "working_tree")
for _, mode in ipairs({ "working_tree", "head", "merge_base" }) do
	modes.action(win, pane, mode)
	assert(selected_ref == "refs/heads/topic" and selected_mode == mode)
	local command = assert(actions[#actions].SpawnCommandInNewTab)
	assert(command.args[3]:find("--no-ext-diff", 1, true) and command.args[3]:find("/fake/delta", 1, true))
	assert(command.args[3]:find("--pager", 1, true), "explicit Delta pager must override repository configuration")
	assert(command.args[3]:find("read", 1, true), "empty diffs/errors remain visible until acknowledgment")
end
refs.action(win, pane, refs.choices[2].id)
local prompt = assert(actions[#actions].PromptInputLine)
prompt.action(win, pane, nil)
local before = #actions
prompt.action(win, pane, "stale")
local mode = actions[#actions].InputSelector
mode.action(win, pane, "head")
assert(#actions == before + 1 and notices[#notices]:find("Revision no longer exists", 1, true))
local rows = {
	{ path = "/home/test/topic", branch = "refs/heads/topic", locked = "reason\27[31m" },
	{ path = "/outside/detached", detached = true, head = string.rep("a", 40) },
	{ path = "/missing", prunable = "missing" },
	{ path = pane.cwd, branch = "refs/heads/main" },
}
function repo.worktrees() return rows end
function repo.validate_worktree(_, path)
	queries[#queries + 1] = "validate:" .. path
	if path == "/missing" then
		return nil, "Worktree missing/prunable"
	end
	for _, row in ipairs(rows) do
		if row.path == path then
			return row
		end
	end
end
function win:active_workspace() return self.workspace or "old" end
native.mux.get_workspace_names = function() return { "~/topic/" } end
reset()
local switch = git.switch_worktree()
assert(#queries == 0)
switch(win, pane)
local trees = assert(actions[1].InputSelector)
assert(#trees.choices == 4 and trees.choices[1].id == rows[1].path)
assert(trees.choices[1].label:find("[open]", 1, true))
assert(trees.choices[2].label:find("detached aaaaaaaa", 1, true))
assert(trees.choices[4].label:find("[current]", 1, true))
assert(trees.choices[1].label:find("locked", 1, true) and not trees.choices[1].label:find("\27", 1, true))
assert(trees.choices[2].label:find("detached", 1, true) and trees.choices[3].label:find("prunable", 1, true))
trees.action(win, pane, nil)
trees.action(win, pane, "unknown")
assert(#actions == 1)
trees.action(win, pane, "/home/test/topic")
assert(actions[2].SwitchToWorkspace.name == "~/topic/" and actions[2].SwitchToWorkspace.spawn == nil)
assert(native.GLOBAL.wezmacs_workspace_previous == "old")
trees.action(win, pane, "/outside/detached")
local workspace = actions[3].SwitchToWorkspace
assert(
	workspace.name == "/outside/detached" and workspace.spawn.cwd == "/outside/detached" and workspace.spawn.args == nil,
	"normal interactive default shell at destination"
)
local count = #actions
trees.action(win, pane, "/missing")
assert(#actions == count and notices[#notices]:find("missing", 1, true))
win.workspace = "~/topic/"
trees.action(win, pane, "/home/test/topic")
assert(#actions == count and native.GLOBAL.wezmacs_workspace_previous == "old", "current selection preserves history")
for _, opts in ipairs({
	{ split_size = 0 },
	{ split_size = 1 },
	{ split_size = "half" },
	{ split_size = 0 / 0 },
	{ split_direction = "Diagonal" },
	{ comparison_mode = "invalid" },
	{ commit_limit = 501 },
	{ commit_limit = -1 },
	{ commit_limit = 1.5 },
	{ direnv = "allow" },
	{ lazygit_path = "lazygit --bad" },
	{ git_path = "git\0bad" },
	{ shell = "sh -c" },
	{ broot = "yes" },
	{ lazyjj = 1 },
}) do
	assert(not pcall(git.lazygit, opts), "invalid option must fail during construction")
end
assert(not pcall(git.lazygit, {}, "window"))
reset()
local spec = require("wezmacs.modules.git")
local keys = spec.keys(spec.opts).LEADER.g
local by_key = {}
for _, key in ipairs(keys) do
	by_key[key.key] = key
end
assert(by_key.g and by_key.G and by_key.d and by_key.D and by_key.w and by_key.h and by_key.H)
assert(not by_key.j and not by_key.s and not by_key.S)
assert(by_key.H.desc == "github/tab" and by_key.D.desc == "compare/tab")
local optional = spec.keys({ broot = true, lazyjj = true }).LEADER.g
local found = {}
for _, key in ipairs(optional) do
	found[key.key] = true
end
assert(found.j and found.s and found.S)
assert(#queries == 0, "module and key construction cannot probe binaries")
local deps = spec.deps({})
assert(table.concat(deps, ",") == "git,lazygit,delta,gh")
assert(table.concat(spec.deps({ broot = true, lazyjj = true }), ",") == "git,lazygit,delta,gh,broot,lazyjj")
-- A blocked environment must not close a diff pane before its error is seen.
reset()
local launcher = require("wezmacs.modules.git.launch")
launcher.diff(
	win,
	pane,
	{ cwd = pane.cwd },
	{ shell = "/bin/sh", direnv = true, direnv_path = "/usr/bin/false" },
	"tab",
	{ "/never/run/git" }
)
local blocked = actions[1].SpawnCommandInNewTab.args
local function shell_quote(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
local words = {}
for _, word in ipairs(blocked) do
	words[#words + 1] = shell_quote(word)
end
local process = assert(io.popen(table.concat(words, " ") .. " </dev/null 2>&1"))
local blocked_output = process:read("*a")
local success, _, status = process:close()
assert(not success and status == 1)
assert(blocked_output:find("Press Enter to close.", 1, true), "blocked direnv still holds diff output")
print("PASS Git actions: guarded tools, comparisons, worktrees, options and bindings")
