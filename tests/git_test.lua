package.path = "./?.lua;./?/init.lua;" .. package.path
local count = 0
local function test(name, fn)
	fn()
	count = count + 1
	print("PASS " .. name)
end
local function equal(a, b) assert(a == b, "expected " .. tostring(b) .. ", got " .. tostring(a)) end
local function contains(args, value)
	for _, arg in ipairs(args) do
		if arg == value then
			return true
		end
	end
	return false
end
local function unprotected(args)
	local result, i = { args[1] }, 2
	while i <= #args do
		if args[i] == "--no-optional-locks" or args[i] == "--no-lazy-fetch" then
			i = i + 1
		elseif
			args[i] == "-c" and (args[i + 1] == "core.fsmonitor=false" or args[i + 1] == "diff.autoRefreshIndex=false")
		then
			i = i + 2
		else
			result[#result + 1] = args[i]
			i = i + 1
		end
	end
	return result
end
local function fixture()
	local state = { calls = {}, raw_calls = {}, dirs = {}, handlers = {} }
	local native = {
		home_dir = "/home/test",
		target_triple = "aarch64-apple-darwin",
		run_child_process = function(args)
			state.raw_calls[#state.raw_calls + 1] = args
			args = unprotected(args)
			state.calls[#state.calls + 1] = args
			local key = table.concat(args, "|")
			for _, handler in ipairs(state.handlers) do
				local a, b, c = handler(args, key)
				if a ~= nil then
					return a, b, c
				end
			end
			error("Unexpected query: " .. key)
		end,
		read_dir = function(path)
			assert(state.dirs[path], "missing directory")
			return {}
		end,
	}
	package.loaded.wezterm = native
	for _, name in ipairs({ "repository", "runtime", "actions" }) do
		package.loaded["wezmacs.modules.git." .. name] = nil
	end
	local ok, mod = pcall(require, "wezmacs.modules.git.repository")
	assert(ok, "repository helper must exist: " .. tostring(mod))
	return mod, state, native
end

test("resolve queries the checkout root from a literal subdirectory lazily", function()
	local mod, s = fixture()
	equal(#s.calls, 0)
	local cwd = "/home/test/O'Reilly; $(touch never)/sub"
	s.dirs[cwd] = true
	s.handlers[1] = function(args)
		equal(args[1], "/tools/git binary")
		equal(args[2], "-C")
		equal(args[3], cwd)
		equal(table.concat(args, "|", 4), "rev-parse|--show-toplevel")
		return true, "/home/test/O'Reilly; $(touch never)\n", ""
	end
	local repo, err = mod.resolve(cwd, { git_path = "/tools/git binary" })
	assert(repo, err)
	equal(repo.cwd, "/home/test/O'Reilly; $(touch never)")
	equal(repo.git, "/tools/git binary")
end)
test("resolve refuses absent relative unreadable and non-checkout cwd without guessing", function()
	local mod, s = fixture()
	for _, cwd in ipairs({ false, "", "relative", "/missing", "/bad\0path" }) do
		local repo, err = mod.resolve(cwd)
		equal(repo, nil)
		assert(err)
		equal(#s.calls, 0)
	end
	s.dirs["/not-repo"] = true
	s.handlers[1] = function() return false, "", "not a git repository" end
	local repo, err = mod.resolve("/not-repo")
	equal(repo, nil)
	assert(err and err:find("not a git repository", 1, true))
	equal(#s.calls, 1)
end)
test("default Git uses GUI PATH fallbacks but explicit binaries are authoritative", function()
	local mod, s = fixture()
	s.dirs["/repo"] = true
	s.handlers[1] = function(args)
		if args[1] ~= "/home/test/.local/bin/git" then
			error("spawn failed")
		end
		return true, "/repo\n", ""
	end
	local repo = assert(mod.resolve("/repo"))
	equal(repo.git, "/home/test/.local/bin/git")
	equal(#s.calls, 4)
	s.calls = {}
	local result, err = mod.resolve("/repo", { git_path = "/missing/git" })
	equal(result, nil)
	assert(err)
	equal(#s.calls, 1)
end)
test("working-tree diff verifies literal revision and uses only full commit OID endpoints", function()
	local mod, s = fixture()
	local oid = string.rep("a", 40)
	local ref = "refs/heads/topic;$(touch never)"
	s.handlers[1] = function(args)
		if args[4] == "config" then
			return true, "", ""
		end
		equal(table.concat(args, "|"), "/git|-C|/repo|rev-parse|--verify|--end-of-options|" .. ref .. "^{commit}")
		return true, oid .. "\n", ""
	end
	assert(type(mod.diff_args) == "function", "diff planner must exist")
	local argv, err = mod.diff_args({ cwd = "/repo", git = "/git" }, ref)
	assert(argv, err)
	equal(
		table.concat(unprotected(argv), "|"),
		"/git|-C|/repo|--no-pager|diff|--no-ext-diff|--no-textconv|--ignore-submodules=dirty|--submodule=short|"
			.. oid
			.. "|--"
	)
	s.handlers[1] = function() return false, "", "unknown revision" end
	local args, message = mod.diff_args({ cwd = "/repo", git = "/git" }, "missing")
	equal(args, nil)
	assert(message and message:find("unknown revision", 1, true))
end)
test("head and merge-base modes compare explicit endpoints and report invalid modes or unrelated histories", function()
	local mod, s = fixture()
	local a, b, c = string.rep("a", 40), string.rep("b", 64), string.rep("c", 40)
	s.handlers[1] = function(args)
		if args[4] == "merge-base" then
			equal(args[5], a)
			equal(args[6], b)
			return true, c .. "\n", ""
		end
		return true, (args[7] == "HEAD^{commit}" and b or a) .. "\n", ""
	end
	local repo = { git = "/git", cwd = "/repo" }
	local head = assert(mod.diff_args(repo, "topic", "head"))
	equal(table.concat(head, "|", #head - 2), a .. "|" .. b .. "|--")
	local base = assert(mod.diff_args(repo, "topic", "merge_base"))
	equal(table.concat(base, "|", #base - 2), c .. "|" .. b .. "|--")
	local invalid, err = mod.diff_args(repo, "topic", "typo")
	equal(invalid, nil)
	assert(err and err:find("mode", 1, true))
	s.handlers[1] = function(args)
		if args[4] == "merge-base" then
			return false, "", "no merge base"
		end
		return true, a .. "\n", ""
	end
	local unrelated, message = mod.diff_args(repo, "topic", "merge_base")
	equal(unrelated, nil)
	assert(message and message:find("merge", 1, true))
end)
test("revision validation rejects nonstrings NUL and non-OID Git output", function()
	local mod, s = fixture()
	local repo = { git = "/git", cwd = "/repo" }
	for _, ref in ipairs({ false, "", "bad\0ref" }) do
		local oid, err = mod.verify(repo, ref)
		equal(oid, nil)
		assert(err)
	end
	equal(#s.calls, 0)
	s.handlers[1] = function() return true, "--evil\n", "" end
	local oid, err = mod.verify(repo, "--evil")
	equal(oid, nil)
	assert(err)
	equal(s.calls[1][6], "--end-of-options")
	equal(s.calls[1][7], "--evil^{commit}")
end)
test("revision choices retain qualified IDs filter noncommit tags and bound recent commits", function()
	local mod, s = fixture()
	local oid = string.rep("a", 40)
	s.handlers[1] = function(args, key)
		if args[4] == "for-each-ref" then
			assert(key:find("refs/heads/|refs/remotes/|refs/tags/", 1, true))
			return true,
				"refs/heads/main\0commit\0\nrefs/remotes/origin/main\0commit\0\nrefs/tags/main\0tag\0commit\nrefs/tags/blob\0blob\0\n",
				""
		end
		if args[4] == "log" then
			assert(key:find("--max-count=2", 1, true))
			assert(key:find("-z", 1, true))
			return true, oid .. "\0subject\27[31m evil\ntext\0", ""
		end
		if args[7] == "refs/tags/blob^{commit}" then
			return false, "", "not a commit"
		end
		return true, oid .. "\n", ""
	end
	assert(type(mod.revisions) == "function", "revision discovery must exist")
	local choices = assert(mod.revisions({ git = "/git", cwd = "/repo" }, { commit_limit = 2 }))
	equal(#choices, 4)
	equal(choices[1].id, "refs/heads/main")
	equal(choices[2].id, "refs/remotes/origin/main")
	equal(choices[3].id, "refs/tags/main")
	equal(choices[4].id, oid)
	assert(not choices[4].label:find("%c"))
end)
test("commit_limit rejects unbounded malformed counts and zero omits history", function()
	local mod, s = fixture()
	local repo = { git = "/git", cwd = "/repo" }
	for _, limit in ipairs({ -1, 501, 1.5, "10", math.huge }) do
		local rows, err = mod.revisions(repo, { commit_limit = limit })
		equal(rows, nil)
		assert(err)
	end
	equal(#s.calls, 0)
	s.handlers[1] = function(args)
		equal(args[4], "for-each-ref")
		return true, "", ""
	end
	equal(#assert(mod.revisions(repo, { commit_limit = 0 })), 0)
	equal(#s.calls, 1)
end)
test("ref discovery batches type filtering without per-ref processes and disables signature display", function()
	local mod, s = fixture()
	s.handlers[1] = function(args, key)
		if args[4] == "for-each-ref" then
			assert(key:find("%(objecttype)", 1, true), "batch object types required")
			return true, "refs/heads/main\0commit\0\nrefs/tags/v1\0tag\0commit\nrefs/tags/blob\0blob\0\n", ""
		end
		equal(args[4], "log")
		assert(key:find("--no-show-signature", 1, true))
		assert(key:find("--no-decorate", 1, true))
		return true, "", ""
	end
	local rows, err = mod.revisions({ git = "/git", cwd = "/repo" })
	assert(rows, err)
	equal(#rows, 2)
	equal(#s.calls, 2)
end)
test("worktree porcelain NUL records preserve arbitrary paths detached locked prunable and bare states", function()
	local mod, s = fixture()
	local path = "/home/test/new\nline\t;\27[31m"
	s.handlers[1] = function(args, key)
		equal(key, "/git|-C|/repo|worktree|list|--porcelain|-z")
		return true,
			"worktree /repo\0HEAD abc\0branch refs/heads/main\0\0worktree "
				.. path
				.. "\0HEAD def\0detached\0locked maintenance\nreason\0\0worktree /gone\0HEAD fed\0detached\0prunable gitdir missing\0\0worktree /bare\0bare\0\0",
			""
	end
	assert(type(mod.worktrees) == "function", "worktree discovery must exist")
	local rows = assert(mod.worktrees({ git = "/git", cwd = "/repo" }))
	equal(#rows, 4)
	equal(rows[1].branch, "refs/heads/main")
	equal(rows[2].path, path)
	equal(rows[2].head, "def")
	equal(rows[2].detached, true)
	equal(rows[2].locked, "maintenance\nreason")
	equal(rows[3].prunable, "gitdir missing")
	equal(rows[4].bare, true)
end)
test("worktree acceptance refreshes registration cwd and common-directory identity", function()
	local mod, s = fixture()
	s.dirs["/tree"] = true
	local replaced = false
	s.handlers[1] = function(args)
		if args[4] == "worktree" then
			return true,
				"worktree /tree\0HEAD abc\0detached\0locked\0\0worktree /stale\0prunable\0\0worktree /bare\0bare\0\0",
				""
		end
		if args[5] == "--show-toplevel" then
			return true, "/tree\n", ""
		end
		equal(table.concat(args, "|", 4), "rev-parse|--path-format=absolute|--git-common-dir")
		return true, (replaced and args[3] == "/tree" and "/other/.git" or "/repo/.git") .. "\n", ""
	end
	assert(type(mod.validate_worktree) == "function", "worktree acceptance validation must exist")
	local repo = { git = "/git", cwd = "/repo" }
	equal(assert(mod.validate_worktree(repo, "/tree")).locked, "")
	for _, path in ipairs({ "/unknown", "/stale", "/bare" }) do
		local row, err = mod.validate_worktree(repo, path)
		equal(row, nil)
		assert(err)
	end
	replaced = true
	local row, err = mod.validate_worktree(repo, "/tree")
	equal(row, nil)
	assert(err and err:find("repository", 1, true))
	s.dirs["/tree"] = nil
	equal(mod.validate_worktree(repo, "/tree"), nil)
end)
test("metadata processes disable optional locks and filesystem-monitor commands", function()
	local mod, s = fixture()
	s.dirs["/repo"] = true
	s.handlers[1] = function() return true, "/repo\n", "" end
	assert(mod.resolve("/repo"))
	assert(contains(s.raw_calls[1], "--no-optional-locks"))
	assert(contains(s.raw_calls[1], "core.fsmonitor=false"))
end)
test("process boundaries reject invalid executable values without falling back or spawning", function()
	local _, s = fixture()
	local runtime = require("wezmacs.modules.git.runtime")
	for _, bin in ipairs({ false, "", "/tool\0bad", 42 }) do
		local out, exe, err = runtime.run("git", bin, { "--version" })
		equal(out, nil)
		equal(exe, nil)
		assert(err)
		equal(#s.calls, 0)
	end
end)
test("working-tree argv fails closed for configured filters at execution time without reading values", function()
	local mod, s = fixture()
	local names = "filter.lfs.clean\0filter.lfs.process\0filter.smudgeonly.smudge\0filter.Mixed.Case.process\0"
	s.handlers[1] = function(args)
		if args[4] == "config" then
			equal(table.concat(args, "|", 4), "config|--null|--list|--name-only")
			return true, names, ""
		end
		return true, string.rep("a", 40) .. "\n", ""
	end
	local repo = { git = "/git", cwd = "/repo" }
	local args = assert(mod.diff_args(repo, "HEAD"))
	for _, name in ipairs({ "lfs", "Mixed.Case" }) do
		for _, suffix in ipairs({ "clean=", "process=", "required=true" }) do
			assert(
				contains(args, "filter." .. name .. "." .. suffix),
				"applicable filters must fail instead of executing or returning raw contents"
			)
		end
	end
	assert(not contains(args, "filter.smudgeonly.required=true"), "smudge-only config does not run during diff")
	local definitions = 0
	for i, arg in ipairs(args) do
		if arg == "filter.lfs.clean=" then
			equal(args[i - 1], "-c")
			definitions = definitions + 1
		end
	end
	equal(definitions, 1)
	for _, mode in ipairs({ "head", "merge_base" }) do
		s.calls = {}
		args = assert(mod.diff_args(repo, "HEAD", mode))
		assert(not contains(args, "filter.lfs.required=true"))
		for _, call in ipairs(s.calls) do
			assert(call[4] ~= "config", "committed comparisons do not need worktree filter config")
		end
	end
	names = "filter.cannot=express.clean\0"
	local invalid, err = mod.diff_args(repo, "HEAD")
	equal(invalid, nil)
	assert(err and err:find("filter", 1, true), "unrepresentable -c keys must fail closed")
end)
test("metadata and every generated diff share local-only process protections", function()
	local mod, s = fixture()
	local oid = string.rep("a", 40)
	s.handlers[1] = function() return true, oid .. "\n", "" end
	for _, mode in ipairs({ "working_tree", "head", "merge_base" }) do
		local args = assert(mod.diff_args({ git = "/git", cwd = "/repo" }, "HEAD", mode))
		assert(contains(args, "--no-lazy-fetch"), "generated diff must never fetch missing objects")
		assert(contains(args, "--no-optional-locks"), "generated diff must not acquire optional locks")
		assert(contains(args, "core.fsmonitor=false"), "generated diff must not execute fsmonitor")
		assert(contains(args, "diff.autoRefreshIndex=false"), "diff must not refresh the index")
		assert(
			contains(args, "--ignore-submodules=dirty") and contains(args, "--submodule=short"),
			"submodules are gitlink-only"
		)
	end
	for _, args in ipairs(s.raw_calls) do
		assert(contains(args, "--no-lazy-fetch"), "metadata must never fetch missing objects")
		assert(contains(args, "--no-optional-locks"))
		assert(contains(args, "core.fsmonitor=false"))
	end
	s.handlers[1] = function() return false, "", "missing object" end
	local oid_result, err = mod.verify({ git = "/git", cwd = "/repo" }, "HEAD")
	equal(oid_result, nil)
	assert(err and err:find("local objects", 1, true), "errors must explain the local-only restriction")
end)
print("PASS git tests: " .. count)
