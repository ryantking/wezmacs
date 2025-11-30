--[[
  WezMacs Configuration: Full

  Complete configuration with ALL built-in modules enabled.
  This shows the full power of WezMacs with every feature.

  Copy this file to ~/.config/wezterm/user/config.lua to use it.
]]

return {
  modules = {
    -- UI: Visual styling and appearance
    ui = {
      "appearance",  -- Colors, fonts, visual styling
      "tabbar",      -- Custom tab bar with app icons
      "window",      -- Window padding, scrolling, cursor
    },

    -- Behavior: User interactions
    behavior = {
      "mouse",       -- Mouse selection and link opening
    },

    -- Editing: Keyboard input
    editing = {
      "keybindings",  -- Pane/tab management, navigation (50+ bindings)
    },

    -- Integration: External systems
    integration = {
      "plugins",     -- Workspace switcher, quick domains
    },

    -- Workflows: Feature-focused collections
    workflows = {
      "git",         -- Git integration (lazygit, diff)
      "workspace",   -- Workspace switching and management
      "claude",      -- Claude Code integration
    },
  },

  -- Configure modules with flags
  flags = {
    ui = {
      theme = "Horizon Dark (Gogh)",  -- WezTerm builtin color scheme
      font = "Iosevka Mono",
      font_size = 16,
    },
    editing = {
      leader_key = "Space",
      leader_mod = "CMD",
    },
    workflows = {
      git = {
        leader_key = "g",
        leader_mod = "LEADER",
      },
      workspace = {
        leader_key = "s",
        leader_mod = "LEADER",
      },
      claude = {
        leader_key = "c",
        leader_mod = "LEADER",
      },
    },
  },

  -- Optional: Add custom keybindings after all modules load
  overrides = function(config)
    -- Uncomment to add custom keybindings:
    -- config.keys = config.keys or {}
    -- table.insert(config.keys, {
    --   key = "q",
    --   mods = "CMD",
    --   action = wezterm.action.QuitApplication,
    -- })
  end,
}
