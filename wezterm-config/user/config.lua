--[[
  User Configuration for WezMacs

  This file controls which modules are enabled and how they are configured.
  Edit this file to customize your WezTerm setup.

  Module Categories:
    - ui: Visual styling, colors, fonts, tab bar
    - behavior: Mouse, scrolling, window behavior
    - editing: Keybindings, selection, input modes
    - integration: Plugins, multiplexing
    - workflows: Feature-specific workflows (git, workspace, etc)
]]

return {
  -- Module Selection
  -- List the modules you want enabled. All other modules will be disabled.
  modules = {
    ui = {
      "appearance",    -- Color scheme, fonts, visual styling
      "tabbar",        -- Custom tab bar with icons
    },
    behavior = {
      "mouse",         -- Mouse bindings and behavior
    },
    editing = {
      "keybindings",   -- Keyboard shortcuts and key tables
    },
    workflows = {
      "git",           -- Git integration (lazygit, diff, etc)
      "workspace",     -- Workspace switching and management
      "claude",        -- Claude integration
    },
  },

  -- Module Configuration (Flags)
  -- Configure individual modules without editing their code.
  -- Organization mirrors the modules structure above.
  flags = {
    ui = {
      -- Appearance module flags
      theme = "Horizon Dark (Gogh)",  -- WezTerm builtin color scheme
      font = "Iosevka Mono",
      font_size = 16,
    },
    behavior = {
      -- Behavior module flags
      -- (modules will define their own flags)
    },
    editing = {
      -- Editing module flags
      leader_key = "Space",
      leader_mod = "CMD",
    },
    workflows = {
      -- Workflow module flags (per-module)
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

  -- User Overrides
  -- Apply final customizations after all modules are loaded.
  -- This function is called last, so it takes highest priority.
  overrides = function(config)
    -- Example: Override font size
    -- config.font_size = 18

    -- Example: Add custom keybindings
    -- config.keys = config.keys or {}
    -- table.insert(config.keys, {
    --   key = "q",
    --   mods = "CMD",
    --   action = wezterm.action.QuitApplication,
    -- })

    -- Example: Customize window appearance
    -- config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
  end,
}
