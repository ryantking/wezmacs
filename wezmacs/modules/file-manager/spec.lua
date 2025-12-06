--[[
  Module Spec: file-manager
  Category: tools
  Description: File management with configurable terminal file manager
]]

return {
  name = "file-manager",
  category = "tools",
  description = "File management with yazi terminal file manager",

  dependencies = {
    external = { "yazi" },
    modules = { "keybindings" },
  },

  opts = {
    file_manager = "yazi",
    leader_key = "f",
    leader_mod = "LEADER",
  },

  keys = {
    {
      leader = "f",
      submenu = "file-manager",
      bindings = {
        { key = "f", desc = "File manager in split", action = "actions.file_manager_split" },
        { key = "F", desc = "File manager in new tab", action = "actions.file_manager_new_tab" },
        { key = "s", desc = "File manager with sudo in split", action = "actions.file_manager_sudo_split" },
        { key = "S", desc = "File manager with sudo in tab", action = "actions.file_manager_sudo_tab" },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("yazi")
  end,

  priority = 50,
}
