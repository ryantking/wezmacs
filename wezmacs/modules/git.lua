--[[
  Module: git
  Category: integration
  Description: Lazygit integration with smart splitting and git utilities
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")

-- Define keys function (captured in closure for setup)
local function keys_fn()
  return {
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
  }
end

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

  keys = keys_fn,

  enabled = function(ctx)
    return ctx.has_command("git")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Apply keybindings using the keys function (captured in closure)
    keybindings.apply_keys(config, {
      name = "git",
      keys = keys_fn,
    })
  end,
}
