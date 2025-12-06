--[[
  Module Spec: editors
  Category: development
  Description: External code editor launchers (terminal editor and IDE)
]]

return {
  name = "editors",
  category = "development",
  description = "External code editor launchers",

  dependencies = {
    external = {},
    modules = { "keybindings" },
  },

  opts = {
    editor = "vim",
    ide = "code",
    editor_split_key = "e",
    editor_tab_key = "E",
    ide_key = "i",
  },

  keys = {
    {
      key = "e",
      mods = "LEADER",
      action = "actions.terminal_smart_split",
    },
    {
      key = "E",
      mods = "LEADER",
      action = "actions.terminal_new_tab",
    },
    {
      key = "i",
      mods = "LEADER",
      action = "actions.launch_ide",
    },
  },

  enabled = true,

  priority = 50,
}
