--[[
  Module: git
  Category: integration
  Description: Lazygit integration with smart splitting and git utilities
]]

local keybindings = require("wezmacs.lib.keybindings")
local action_lib = require("wezmacs.lib.actions")

-- Actions (inline)
local actions = {
  lazygit_smart_split = action_lib.smart_split_action("lazygit -sm half"),
  lazygit_new_tab = action_lib.new_tab_action("lazygit"),
  git_diff_smart_split = action_lib.smart_split_action(
    "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status"
  ),
  git_diff_new_window = action_lib.new_window_action(
    "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status"
  ),
}

-- Module spec (LazyVim-style inline spec)
local spec = {
  name = "git",
  category = "integration",
  description = "Lazygit integration with smart splitting and git utilities",

  dependencies = {
    external = { "lazygit", "delta", "git" },
    modules = { "theme", "keybindings" },
  },

  opts = {
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
  },

  keys = {
    {
      leader = "g",
      submenu = "git",
      bindings = {
        { key = "g", desc = "Open lazygit", action = actions.lazygit_smart_split },
        { key = "G", desc = "Lazygit in new tab", action = actions.lazygit_new_tab },
        { key = "d", desc = "Git diff", action = actions.git_diff_smart_split },
        { key = "D", desc = "Git diff in new window", action = actions.git_diff_new_window },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("git")
  end,

  priority = 50,

  -- Implementation function (called by module loader)
  apply_to_config = function(config, opts)
    -- Apply keybindings using library (spec captured in closure)
    keybindings.apply_keys(config, spec)

    -- Any other git-specific config
    -- (none needed for this module)
  end,
}

return spec
