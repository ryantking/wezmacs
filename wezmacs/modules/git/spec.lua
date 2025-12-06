--[[
  Module Spec: git
  Category: integration
  Description: Lazygit integration with smart splitting and git utilities
]]

return {
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
        { key = "g", desc = "Open lazygit", action = "actions.lazygit_smart_split" },
        { key = "G", desc = "Lazygit in new tab", action = "actions.lazygit_new_tab" },
        { key = "d", desc = "Git diff", action = "actions.git_diff_smart_split" },
        { key = "D", desc = "Git diff in new window", action = "actions.git_diff_new_window" },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("git")
  end,

  priority = 50,
}
