-- Execute native launch argv against inert tools, never an installed TUI.
return function(run, repo, fixture)
	local launch = require("wezmacs.modules.git.launch")
	local repository = require("wezmacs.modules.git.repository")
	local stubs = assert(os.getenv("WEZMACS_GIT_STUBS"))
	local spawned
	local window = {
		perform_action = function(_, action) spawned = assert(action.SpawnCommandInNewTab) end,
	}
	local function execute()
		assert(spawned.cwd == repo.cwd, "native spawn retains the selected checkout")
		-- run_child_process has no cwd option; this static wrapper emulates native
		-- spawn's cwd without putting any input into shell syntax.
		local argv = { "/bin/sh", "-c", 'cd "$1" && shift && exec "$@"', "fixture", spawned.cwd }
		for _, arg in ipairs(spawned.args) do
			argv[#argv + 1] = arg
		end
		local success, stdout, stderr = run(argv)
		return success, stdout, stderr
	end
	local opts = { shell = "/bin/sh", direnv = false, delta_path = stubs .. "/delta", direnv_path = stubs .. "/direnv" }
	local literal = "literal ' ; $(touch " .. fixture .. "/injected)"
	launch.run(window, {}, repo, opts, "tab", { stubs .. "/tool", literal })
	local success, stdout, stderr = execute()
	assert(success, stderr)
	assert(stdout:find("<cwd>" .. repo.cwd .. "</cwd>", 1, true), "tool starts in literal checkout cwd")
	assert(stdout:find("<arg>" .. literal .. "</arg>", 1, true), "shell metacharacters remain literal arguments")
	assert(not stdout:find("<direnv>", 1, true), "disabled direnv is not run")
	opts.direnv = true
	launch.run(window, {}, repo, opts, "tab", { stubs .. "/tool", literal })
	success, stdout, stderr = execute()
	assert(success, stderr)
	assert(stdout:find("<direnv>" .. repo.cwd .. "</direnv>", 1, true), "direnv exec uses selected checkout")
	assert(stdout:find("<arg>" .. literal .. "</arg>", 1, true), "direnv wrapper preserves argv")
	opts.direnv = false
	local args, err = repository.diff_args(repo, "v1", "working_tree")
	assert(args, err)
	launch.diff(window, {}, repo, opts, "tab", args)
	success, stdout, stderr = execute()
	assert(success, stderr)
	assert(stdout:find("<delta>", 1, true) and stdout:find("main.txt", 1, true), "real diff reaches inert pager")
	assert(stdout:find("Press Enter", 1, true), "diff remains visible until dismissed")
	launch.diff(window, {}, repo, opts, "tab", { "/bin/sh", "-c", "exit 23" })
	success, stdout = execute()
	assert(not success, "Git failure must not be hidden by pager success")
	assert(not stdout:find("<delta>", 1, true), "failed Git command never runs pager")
	assert(stdout:find("23", 1, true) and stdout:find("Press Enter", 1, true), "diff failure remains readable")
	local empty_args, empty_err = repository.diff_args(repo, "HEAD", "head")
	assert(empty_args, empty_err)
	launch.diff(window, {}, repo, opts, "tab", empty_args)
	success, stdout, stderr = execute()
	assert(success, stderr)
	assert(stdout:find("Press Enter", 1, true), "empty comparison does not disappear immediately")
	local real_delta = os.getenv("WEZMACS_GIT_REAL_DELTA")
	if real_delta then
		opts.delta_path = real_delta
		launch.diff(window, {}, repo, opts, "tab", args)
		success, stdout, stderr = execute()
		assert(success, stderr)
		assert(
			stdout:find("main.txt", 1, true),
			"installed Delta must receive and render the patch, not silently ignore a filename"
		)
		opts.delta_path = stubs .. "/delta"
	end
	local splits = {}
	local split_window = {
		perform_action = function(_, action) splits[#splits + 1] = assert(action.SplitPane) end,
	}
	for _, direction in ipairs({ "Left", "Right", "Up", "Down" }) do
		local split_opts =
			launch.validate({ shell = "/bin/sh", direnv = false, split_direction = direction, split_size = 0.5 })
		launch.run(split_window, {}, repo, split_opts, "split", { stubs .. "/tool" })
		assert(splits[#splits].direction == direction and splits[#splits].size.Percent == 50, "native split option schema")
	end
	print("PASS real Git launch argv (literal quoting, direnv exec, diff status and empty output)")
end
