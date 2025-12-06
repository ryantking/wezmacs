--[[
  Module Spec: keybindings
  Category: editing
  Description: Core keyboard bindings for pane/tab management, selection, and navigation
]]

return {
  name = "keybindings",
  category = "editing",
  description = "Core keyboard bindings for pane and tab management",

  dependencies = {
    external = {},
    modules = {},
  },

  opts = {
    modifier = "CTRL|SHIFT",
    leader_key = "Space",
    leader_mod = "SUPER",
  },

  keys = {},

  enabled = true,

  priority = 100,  -- High priority, loads early
}
