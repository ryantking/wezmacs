-- POSIX terminal boundary. Every dynamic argument is shell-quoted, never code.
local wezterm = require("wezterm")
local runtime = require("wezmacs.modules.git.runtime")
local M = {}
local function executable(value, key)
	assert(
		type(value) == "string"
			and value ~= ""
			and not value:find("%c")
			and (value:find("/", 1, true) or not value:find("%s")),
		key .. " must be a single executable, not a shell command"
	)
end
function M.validate(opts, placement)
	opts = opts or {}
	assert(type(opts) == "table", "Git opts must be a table")
	assert(placement == nil or placement == "split" or placement == "tab", "Git placement must be split or tab")
	if opts.split_size ~= nil then
		assert(
			type(opts.split_size) == "number" and opts.split_size >= 0.01 and opts.split_size <= 0.99,
			"split_size must be a fraction from .01 to .99"
		)
	end
	if opts.split_direction ~= nil then
		assert(
			({ Left = true, Right = true, Up = true, Down = true })[opts.split_direction],
			"split_direction must be Left, Right, Up or Down"
		)
	end
	if opts.comparison_mode ~= nil then
		assert(
			({ working_tree = true, head = true, merge_base = true })[opts.comparison_mode],
			"comparison_mode must be working_tree, head or merge_base"
		)
	end
	if opts.commit_limit ~= nil then
		assert(
			type(opts.commit_limit) == "number"
				and opts.commit_limit >= 0
				and opts.commit_limit <= 500
				and opts.commit_limit % 1 == 0,
			"commit_limit must be an integer from 0 to 500"
		)
	end
	assert(
		opts.direnv == nil or opts.direnv == "auto" or type(opts.direnv) == "boolean",
		"direnv must be auto, true or false"
	)
	for _, key in ipairs({ "broot", "lazyjj" }) do
		assert(opts[key] == nil or type(opts[key]) == "boolean", key .. " must be boolean")
	end
	for _, key in ipairs({
		"git_path",
		"lazygit_path",
		"delta_path",
		"direnv_path",
		"gh_path",
		"broot_path",
		"lazyjj_path",
		"shell",
	}) do
		if opts[key] ~= nil then
			executable(opts[key], key)
		end
	end
	return opts
end
local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end
local function join(argv)
	local words = {}
	for _, value in ipairs(argv) do
		words[#words + 1] = quote(value)
	end
	return table.concat(words, " ")
end
local function environment(repo, opts, argv)
	if opts.direnv == false then
		return argv
	end
	local output, bin, err = runtime.run("direnv", opts.direnv_path, { "--version" })
	if not output then
		if opts.direnv == true then
			error(err)
		end
		return argv
	end
	local wrapped = { bin, "exec", repo.cwd }
	for _, value in ipairs(argv) do
		wrapped[#wrapped + 1] = value
	end
	return wrapped
end
local function spawn(window, pane, repo, opts, placement, argv)
	local shell = opts.shell or require("wezmacs").config.shell
	local command = { cwd = repo.cwd, domain = "CurrentPaneDomain", args = { shell, "-lc", "exec " .. join(argv) } }
	local action
	if placement == "tab" then
		action = wezterm.action.SpawnCommandInNewTab(command)
	else
		action = wezterm.action.SplitPane({
			direction = opts.split_direction or "Right",
			size = { Percent = math.floor((opts.split_size or 0.5) * 100 + 0.5) },
			command = command,
		})
	end
	window:perform_action(action, pane)
end
function M.run(window, pane, repo, opts, placement, argv)
	spawn(window, pane, repo, opts, placement, environment(repo, opts, argv))
end
function M.diff(window, pane, repo, opts, placement, argv)
	local output, delta, err = runtime.run("delta", opts.delta_path, { "--version" })
	if not output then
		error(err)
	end
	-- A private file avoids a pipeline hiding Git's status. Do not evaluate Git's
	-- configured pager; force Delta's pager policy and retain empty/error output.
	local script = [[
file=$(mktemp "${TMPDIR:-/tmp}/wezmacs-diff.XXXXXX") || { printf '%s\n' 'Cannot create diff file'; exit 1; }
trap 'rm -f "$file"' EXIT
trap 'exit 130' HUP INT TERM
]] .. join(argv) .. [[ >"$file"
status=$?
if [ "$status" -eq 0 ]; then
 DELTA_PAGER='less -R' PAGER='less -R' LESSSECURE=1 ]] .. join({ delta, "--paging", "always", "--pager", "less -R" }) .. [[ <"$file"
 status=$?
else
 printf 'Git diff failed (status %s).\n' "$status"
fi
exit "$status"
]]
	-- A blocked .envrc fails before the child starts; acknowledgment must live
	-- outside direnv, not inside the program that direnv may refuse to execute.
	local wrapped = environment(repo, opts, { "/bin/sh", "-c", script })
	local hold = join(wrapped) .. "\n" .. [[
status=$?
printf '\nPress Enter to close.\n'
read -r answer
exit "$status"
]]
	spawn(window, pane, repo, opts, placement, { "/bin/sh", "-c", hold })
end
return M
