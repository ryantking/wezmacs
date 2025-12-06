--[[
  Module: git
  Category: integration
  Description: Lazygit integration with smart splitting and git utilities
]]

local act = require("wezmacs.action")

return {
  name = "git",
  category = "integration",
  description = "Lazygit integration with smart splitting and git utilities",

  deps = { "lazygit", "delta", "git" },

  opts = function()
    return {
      leader_key = "g",
      leader_mod = "LEADER",
      features = {
        lazygit = {
          enabled = true,
          split_mode = "half",
        },
        git_diff = { enabled = true },
        git_log = { enabled = true },
      },
    }
  end,

  keys = {
    LEADER = {
      g = {
        g = { action = act.SmartSplit("lazygit -sm half"), desc = "git/lazygit-split" },
        G = { action = act.NewTab("lazygit"), desc = "git/lazygit-tab" },
        d = {
          action = act.SmartSplit(
            "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status"
          ),
          desc = "git/diff-split",
        },
        D = {
          action = act.NewWindow(
            "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status"
          ),
          desc = "git/diff-window",
        },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("git")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Module-specific setup (if any)
  end,
}
