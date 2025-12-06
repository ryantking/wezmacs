--[[
  Module Spec: workspace
  Category: workflows
  Description: WezTerm workspace switching and management with fuzzy search
]]

return {
  name = "workspace",
  category = "workflows",
  description = "Workspace switching and management",

  dependencies = {
    external = {},
    modules = {},
  },

  opts = {
    default_workspace = "~",
    switch_key = "s",
    switch_mod = "LEADER",
    prev_key = "S",
    prev_mod = "LEADER",
  },

  keys = {
    {
      key = "s",
      mods = "LEADER",
      action = "actions.switch_workspace",
    },
    {
      key = "S",
      mods = "LEADER",
      action = "actions.switch_to_prev_workspace",
    },
  },

  enabled = true,

  priority = 50,
}
