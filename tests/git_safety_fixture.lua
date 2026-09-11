-- Real Git safety boundary under embedded Lua; fixture setup is test-owned.
local wezterm = require("wezterm")
local ok, config = xpcall(function()
	local root = assert(os.getenv("WEZMACS_SMOKE_ROOT"))
	local fixture = assert(os.getenv("WEZMACS_GIT_SAFETY"))
	package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
	local native_run = wezterm.run_child_process
	wezterm.run_child_process = function(args)
		local present = {}
		for _, arg in ipairs(args) do
			present[arg] = true
		end
		assert(present["--no-lazy-fetch"] and present["--no-optional-locks"] and present["core.fsmonitor=false"])
		assert(present["rev-parse"] or present["config"] or present["merge-base"] or present["diff"])
		if present["config"] then
			assert(present["--list"] and present["--name-only"] and present["--null"], "config values forbidden")
		end
		local function index_bytes()
			for i, arg in ipairs(args) do
				if arg == "-C" then
					local file = io.open(args[i + 1] .. "/.git/index", "rb")
					if file then
						local bytes = file:read("*a")
						file:close()
						return bytes
					end
				end
			end
		end
		local before = index_bytes()
		local success, stdout, stderr = native_run(args)
		assert(before == index_bytes(), "index changed: " .. table.concat(args, " | "))
		return success, stdout, stderr
	end
	local repository = require("wezmacs.modules.git.repository")
	local function repo(name)
		local result, err = repository.resolve(fixture .. "/" .. name)
		assert(result, err)
		return result
	end
	local function diff(target, revision, mode)
		local args, err = repository.diff_args(target, revision, mode)
		assert(args, err)
		return wezterm.run_child_process(args)
	end
	for _, name in ipairs({ "ordinary", "untracked-only", "no-helper" }) do
		local success, output, err = diff(repo(name), "HEAD", "working_tree")
		assert(success, err)
		if name == "ordinary" then
			assert(output == "", "built-in CRLF normalization must retain normal Git diff semantics")
		end
	end
	for _, name in ipairs({ "clean", "process", "info-attribute", "index-attribute" }) do
		local target = repo(name)
		local success, _, err = diff(target, "HEAD", "working_tree")
		assert(not success and err:find("clean filter", 1, true), "must fail closed instead of showing raw diff: " .. err)
		for _, mode in ipairs({ "head", "merge_base" }) do
			local committed, output, committed_err = diff(target, "HEAD~1", mode)
			assert(committed, committed_err)
			assert(output:find("+second", 1, true), "normal committed diff remains usable")
		end
	end
	local submodules = repo("submodules")
	local sub_ok, sub_output, sub_err = diff(submodules, "HEAD", "working_tree")
	assert(sub_ok, sub_err)
	local marker = io.open(fixture .. "/clean-ran", "r")
	if marker then
		marker:close()
		error("submodule clean helper executed")
	end
	assert(sub_output:find("Subproject commit", 1, true), "gitlink movement remains visible")
	assert(not sub_output:find("dirty submodule", 1, true), "submodule contents must not be traversed")
	local partial = repo("partial")
	local missing, missing_err = repository.verify(partial, string.rep("1", 40))
	assert(
		not missing and missing_err and missing_err:find("local objects", 1, true),
		"missing commits fail with local-only context"
	)
	local success, _, err = diff(partial, "HEAD~1", "head")
	assert(not success and err ~= "", "missing promisor blobs must fail locally")
	local built = wezterm.config_builder()
	---@cast built WezmacsConfigBuilder
	built:set_strict_mode(true)
	built.keys = {
		{
			key = "F24",
			mods = "CTRL|SHIFT|ALT|SUPER",
			action = wezterm.action.SendString("__WEZMACS_GIT_SAFETY_VALIDATED__"),
		},
	}
	print("PASS real Git safety fixture")
	return built
end, tostring)
if not ok then
	io.stderr:write(tostring(config), "\n")
	os.exit(1)
end
return config
