--[[
  Module Spec: claude
  Category: workflows
  Description: Claude Code integration with workspace management
]]

return {
  name = "claude",
  category = "workflows",
  description = "Claude Code integration and workspace management",

  dependencies = {
    external = { "claude", "agentctl" },
    modules = { "keybindings" },
  },

  opts = {
    leader_key = "c",
    leader_mod = "LEADER",
  },

  keys = {
    {
      leader = "c",
      submenu = "claude",
      bindings = {
        { key = "c", desc = "Claude in split", action = "actions.claude_smart_split" },
        { key = "C", desc = "Claude in new tab", action = "actions.claude_new_tab" },
        { key = "w", desc = "Create workspace", action = "actions.create_agentctl_workspace" },
        { key = "Space", desc = "List workspaces", action = "actions.list_agentctl_sessions" },
        { key = "s", desc = "Switch workspace", action = "actions.list_agentctl_sessions" },
        { key = "d", desc = "Delete workspace", action = "actions.delete_agentctl_session" },
      },
    },
    {
      key = "Enter",
      mods = "SHIFT",
      action = function(window, pane)
        local act = wezterm.action
        return act.SendString("\x1b\r")
      end,
    },
  },

  enabled = function(ctx)
    return ctx.has_command("claude")
  end,

  priority = 50,
}
