-- Real local Git repository APIs under WezTerm's embedded Lua. No GUI or hooks.
local wezterm = require("wezterm")
local ok, config = xpcall(function()
	local root = assert(os.getenv("WEZMACS_SMOKE_ROOT"))
	local fixture = assert(os.getenv("WEZMACS_GIT_FIXTURE"))
	local main = assert(os.getenv("WEZMACS_GIT_REPO"))
	local linked = assert(os.getenv("WEZMACS_GIT_LINKED"))
	local detached = assert(os.getenv("WEZMACS_GIT_DETACHED"))
	local missing = assert(os.getenv("WEZMACS_GIT_MISSING"))
	local replaced = assert(os.getenv("WEZMACS_GIT_REPLACED"))
	local base_oid = assert(os.getenv("WEZMACS_GIT_BASE"))
	local main_oid = assert(os.getenv("WEZMACS_GIT_MAIN"))
	local feature_oid = assert(os.getenv("WEZMACS_GIT_FEATURE"))
	package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
	rawset(package.preload, "wezmacs", function() error("metadata helper must not load personal configuration") end)
	wezterm.background_child_process = function() error("background launch forbidden") end
	local run = wezterm.run_child_process
	local queries = 0
	wezterm.run_child_process = function(argv)
		local stubs = assert(os.getenv("WEZMACS_GIT_STUBS"))
		if
			argv[1] == stubs .. "/direnv"
			or argv[1] == stubs .. "/delta"
			or argv[1] == os.getenv("WEZMACS_GIT_REAL_DELTA")
		then
			assert(#argv == 2 and argv[2] == "--version", "only inert version probes allowed")
			return run(argv)
		end
		local allowed = false
		for index, arg in ipairs(argv) do
			if arg == "worktree" then
				assert(argv[index + 1] == "list", "worktree mutation forbidden")
				allowed = true
			elseif arg == "config" then
				assert(
					argv[index + 1] == "--null"
						and argv[index + 2] == "--list"
						and argv[index + 3] == "--name-only"
						and #argv == index + 3,
					"only name-only config reads allowed"
				)
				allowed = true
			elseif arg == "ls-files" or arg == "check-attr" then
				allowed = true
			elseif arg == "rev-parse" or arg == "for-each-ref" or arg == "log" or arg == "merge-base" or arg == "diff" then
				allowed = true
			end
		end
		assert(allowed, "only read-only Git metadata commands allowed")
		queries = queries + 1
		return run(argv)
	end
	local repository = require("wezmacs.modules.git.repository")
	assert(queries == 0, "requiring metadata must not query Git")
	local repo, err = repository.resolve(main .. "/subdir")
	assert(repo, err)
	assert(repo.cwd == main, "nested directory must resolve literal checkout path")
	local other, other_err = repository.resolve(linked)
	assert(other, other_err)
	assert(other.cwd == linked, "linked worktree must not resolve back to main checkout")
	assert(repository.resolve(fixture) == nil, "outside a repository must fail clearly")
	assert(repository.resolve(main .. "/absent") == nil, "missing cwd must not fall back to process cwd")
	assert(repository.verify(repo, "v1") == base_oid, "annotated tag must peel to a commit")
	assert(repository.verify(repo, "refs/heads/main") == main_oid)
	assert(repository.verify(repo, "feature/literal$ref") == feature_oid, "literal branch metacharacter")
	assert(repository.verify(repo, "blob-tag") == nil, "non-commit tag must be rejected")
	assert(repository.verify(repo, "--help") == nil, "revision must not be interpreted as a flag")
	assert(
		repository.verify(repo, "HEAD; touch " .. fixture .. "/injected") == nil,
		"revision must never execute a shell"
	)
	local revisions, refs_err = repository.revisions(repo, { commit_limit = 1 })
	assert(revisions, refs_err)
	local ids = {}
	for _, choice in ipairs(revisions) do
		ids[choice.id] = true
	end
	assert(ids["refs/heads/main"] and ids["refs/heads/feature/literal$ref"], "qualified local branch identities")
	assert(ids["refs/tags/v1"] and not ids["refs/tags/blob-tag"], "offer only commit-resolving tags")
	local rows, rows_err = repository.worktrees(repo)
	assert(rows, rows_err)
	assert(#rows == 5, "all registered worktrees are returned, even agent-owned and stale")
	local by_path = {}
	for _, row in ipairs(rows) do
		by_path[row.path] = row
	end
	assert(
		by_path[main] and by_path[linked] and by_path[detached] and by_path[missing],
		"NUL parsing preserves newline paths"
	)
	assert(by_path[linked].branch == "refs/heads/feature/literal$ref")
	assert(by_path[detached].detached and by_path[detached].locked == "agent-owned fixture")
	assert(by_path[missing].prunable, "missing registration is not silently pruned")
	assert(repository.validate_worktree(repo, linked), "existing linked checkout is selectable")
	assert(repository.validate_worktree(repo, detached), "locked detached checkout can be opened read-only")
	assert(repository.validate_worktree(repo, missing) == nil, "stale checkout cannot be opened")
	assert(repository.validate_worktree(repo, replaced) == nil, "replacement with unrelated repository cannot be opened")
	assert(repository.validate_worktree(repo, fixture) == nil, "unoffered checkout cannot be opened")
	local function diff(mode)
		local args, diff_err = repository.diff_args(other, "refs/heads/main", mode)
		assert(args, diff_err)
		assert(args[#args] == "--", "explicit revision/path separator")
		local success, stdout, stderr = wezterm.run_child_process(args)
		assert(success, stderr)
		return stdout
	end
	local working = diff("working_tree")
	assert(
		working:find("tracked.txt", 1, true) and working:find("feature.txt", 1, true),
		"working diff includes dirty tracked files"
	)
	local head = diff("head")
	assert(not head:find("tracked.txt", 1, true), "committed endpoint diff excludes uncommitted changes")
	assert(
		head:find("main.txt", 1, true) and head:find("feature.txt", 1, true),
		"endpoint diff includes divergence on both branches"
	)
	local merged = diff("merge_base")
	assert(merged:find("feature.txt", 1, true), "merge-base diff includes branch changes")
	assert(
		not merged:find("tracked.txt", 1, true) and not merged:find("main.txt", 1, true),
		"merge-base diff excludes dirt and base-only changes"
	)
	assert(repository.diff_args(other, "main", "invalid") == nil, "invalid mode fails closed")
	assert(repository.diff_args(other, "absent-ref", "head") == nil, "missing comparison ref is not replaced by another")
	require("tests.git_launch_fixture")(run, repo, fixture)
	local built = wezterm.config_builder()
	---@cast built WezmacsConfigBuilder
	built:set_strict_mode(true)
	built.keys = {
		{
			key = "F24",
			mods = "CTRL|SHIFT|ALT|SUPER",
			action = wezterm.action.SendString("__WEZMACS_GIT_FIXTURE_VALIDATED__"),
		},
	}
	print("PASS real Git fixture")
	return built
end, tostring)
if not ok then
	io.stderr:write(tostring(config), "\n")
	os.exit(1)
end
return config
