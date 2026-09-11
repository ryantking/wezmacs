-- Composition only; native discovery happens when a callback opens.
local actions = require("wezmacs.modules.git.actions")
return {
	name = "git",
	description = "Native Git comparisons, worktrees and terminal tools",
	opts = {
		split_direction = "Right",
		split_size = 0.5,
		comparison_mode = "working_tree",
		commit_limit = 50,
		direnv = "auto",
		broot = false,
		lazyjj = false,
	},
	deps = function(opts)
		local deps = { "git", "lazygit", "delta", "gh" }
		if opts.broot then
			deps[#deps + 1] = "broot"
		end
		if opts.lazyjj then
			deps[#deps + 1] = "lazyjj"
		end
		return deps
	end,
	keys = function(opts)
		local keys = {
			{ key = "g", action = actions.lazygit(opts), desc = "lazygit/split" },
			{ key = "G", action = actions.lazygit(opts, "tab"), desc = "lazygit/tab" },
			{ key = "d", action = actions.compare(opts), desc = "compare/split" },
			{ key = "D", action = actions.compare(opts, "tab"), desc = "compare/tab" },
			{ key = "w", action = actions.switch_worktree(opts), desc = "worktrees" },
			{ key = "h", action = actions.tool("gh", opts), desc = "github/split" },
			{ key = "H", action = actions.tool("gh", opts, "tab"), desc = "github/tab" },
		}
		if opts.broot then
			keys[#keys + 1] = { key = "s", action = actions.tool("broot", opts), desc = "status/split" }
			keys[#keys + 1] = { key = "S", action = actions.tool("broot", opts, "tab"), desc = "status/tab" }
		end
		if opts.lazyjj then
			keys[#keys + 1] = { key = "j", action = actions.tool("lazyjj", opts), desc = "lazyjj/split" }
		end
		return { LEADER = { g = keys } }
	end,
}
