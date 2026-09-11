-- Local, read-only Git metadata. Callers must establish locality before using cwd.
local wezterm = require("wezterm")
local runtime = require("wezmacs.modules.git.runtime")
local M = {}

function M.resolve(cwd, opts)
	if type(cwd) ~= "string" or cwd:sub(1, 1) ~= "/" or cwd:find("\0", 1, true) or not pcall(wezterm.read_dir, cwd) then
		return nil, "Git requires a readable absolute checkout directory."
	end
	local stdout, git, err = runtime.run("git", (opts or {}).git_path, { "-C", cwd, "rev-parse", "--show-toplevel" })
	if not stdout then
		return nil, err
	end
	return { cwd = stdout:gsub("\n$", ""), git = git }
end
local function query(repo, args)
	local argv = { "-C", repo.cwd }
	for _, arg in ipairs(args) do
		argv[#argv + 1] = arg
	end
	local out, _, err = runtime.run("git", repo.git, argv)
	return out, err
end
local function commit_oid(out)
	local oid = out:gsub("\n$", "")
	if not oid:match("^%x+$") or (#oid ~= 40 and #oid ~= 64) then
		return nil, "Git returned an invalid commit OID."
	end
	return oid
end
function M.verify(repo, revision)
	if type(revision) ~= "string" or revision == "" or revision:find("\0", 1, true) then
		return nil, "Enter a valid Git revision."
	end
	local out, err = query(repo, { "rev-parse", "--verify", "--end-of-options", revision .. "^{commit}" })
	if not out then
		return nil, err
	end
	return commit_oid(out)
end
local function working_tree_filter_args(repo)
	-- Read names, never command values. Required + empty commands makes Git fail
	-- when normalization is needed, not silently compare unfiltered file contents.
	local names, err = query(repo, { "config", "--null", "--list", "--name-only" })
	if not names then
		return nil, err
	end
	local args, seen = {}, {}
	for key in names:gmatch("([^%z]+)%z") do
		local name, kind = key:match("^filter%.(.+)%.([^%.]+)$")
		if name and (kind == "clean" or kind == "process") and not seen[name] then
			if name:find("=", 1, true) then
				return nil, "Cannot safely override configured filter name; use head or merge_base comparison."
			end
			seen[name] = true
			for _, suffix in ipairs({ "clean=", "process=", "required=true" }) do
				args[#args + 1] = "-c"
				args[#args + 1] = "filter." .. name .. "." .. suffix
			end
		end
	end
	return args
end
function M.diff_args(repo, revision, mode)
	mode = mode or "working_tree"
	if mode ~= "working_tree" and mode ~= "head" and mode ~= "merge_base" then
		return nil, "Unknown comparison mode: " .. tostring(mode)
	end
	local oid, err = M.verify(repo, revision)
	if not oid then
		return nil, err
	end
	local head
	local options = { "-C", repo.cwd, "--no-pager" }
	if mode == "working_tree" then
		local filters
		filters, err = working_tree_filter_args(repo)
		if not filters then
			return nil, err
		end
		for _, arg in ipairs(filters) do
			options[#options + 1] = arg
		end
	else
		head, err = M.verify(repo, "HEAD")
		if not head then
			return nil, err
		end
		if mode == "merge_base" then
			oid, err = query(repo, { "merge-base", oid, head })
			if not oid then
				return nil, err
			end
			oid, err = commit_oid(oid)
			if not oid then
				return nil, err
			end
		end
	end
	-- Do not inspect nested worktree contents/config: show gitlink changes only.
	for _, arg in ipairs({
		"diff",
		"--no-ext-diff",
		"--no-textconv",
		"--ignore-submodules=dirty",
		"--submodule=short",
		oid,
	}) do
		options[#options + 1] = arg
	end
	local args = runtime.git_args(repo.git, options)
	if head then
		args[#args + 1] = head
	end
	args[#args + 1] = "--"
	return args
end
function M.revisions(repo, opts)
	local limit = (opts or {}).commit_limit
	if limit == nil then
		limit = 50
	end
	if type(limit) ~= "number" or limit < 0 or limit > 500 or limit ~= math.floor(limit) then
		return nil, "commit_limit must be an integer from 0 to 500."
	end
	local out, err = query(repo, {
		"for-each-ref",
		"--format=%(refname)%00%(objecttype)%00%(*objecttype)",
		"refs/heads/",
		"refs/remotes/",
		"refs/tags/",
	})
	if not out then
		return nil, err
	end
	local choices = {}
	for ref, kind, peeled in out:gmatch("([^%z\n]+)%z([^%z]*)%z([^\n]*)\n") do
		if kind == "commit" or peeled == "commit" or (peeled == "tag" and M.verify(repo, ref)) then
			choices[#choices + 1] = { id = ref, label = runtime.label(ref) }
		end
	end
	if limit > 0 then
		out, err = query(
			repo,
			{ "log", "--no-show-signature", "--no-decorate", "--all", "--max-count=" .. limit, "-z", "--format=%H%x00%s" }
		)
		if not out then
			return nil, err
		end
		for oid, subject in out:gmatch("([^%z]+)%z([^%z]*)%z") do
			if commit_oid(oid) then
				choices[#choices + 1] = { id = oid, label = oid:sub(1, 12) .. " " .. runtime.label(subject) }
			end
		end
	end
	return choices
end
function M.worktrees(repo)
	local out, err = query(repo, { "worktree", "list", "--porcelain", "-z" })
	if not out then
		return nil, err
	end
	local rows, row = {}, nil
	for field in out:gmatch("([^%z]*)%z") do
		if field == "" then
			if row then
				rows[#rows + 1] = row
				row = nil
			end
		else
			local key, value = field:match("^(%S+)%s(.*)$")
			key, value = key or field, value or ""
			if key == "worktree" then
				row = { path = value }
			elseif row then
				if key == "HEAD" then
					row.head = value
				elseif key == "branch" or key == "locked" or key == "prunable" then
					row[key] = value
				elseif key == "detached" or key == "bare" then
					row[key] = true
				end
			end
		end
	end
	return rows
end
function M.validate_worktree(repo, path)
	local rows, err = M.worktrees(repo)
	if not rows then
		return nil, err
	end
	for _, row in ipairs(rows) do
		if row.path == path then
			if row.bare or row.prunable then
				return nil, "Worktree is bare or prunable; reopen the picker after repairing it."
			end
			local target
			target, err = M.resolve(path, { git_path = repo.git })
			if not target then
				return nil, err
			end
			if target.cwd ~= path then
				return nil, "Worktree path no longer identifies its checkout."
			end
			local common, other
			common, err = query(repo, { "rev-parse", "--path-format=absolute", "--git-common-dir" })
			if not common then
				return nil, err
			end
			other, err = query(target, { "rev-parse", "--path-format=absolute", "--git-common-dir" })
			if not other then
				return nil, err
			end
			if common ~= other then
				return nil, "Worktree now belongs to a different repository."
			end
			return row
		end
	end
	return nil, "Worktree is no longer registered; reopen the picker."
end
return M
