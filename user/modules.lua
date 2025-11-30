--[[
  WezMacs Module Selection

  This file specifies WHICH modules to load and WHICH feature flags to enable.

  Format:
  - Simple string: Load module with default settings
    "appearance"

  - Table with flags: Load module and enable specific features
    { name = "git", flags = {"smartsplit", "diff-viewer"} }

  See ~/.config/wezmacs/config.lua for per-module configuration.
]]

return {
  -- UI Modules
  "appearance",  -- Color scheme, fonts, visual styling
  "tabbar",      -- Custom tab bar with icons
  "window",      -- Window padding, scrolling, behavior

  -- Behavior Modules
  "mouse",       -- Mouse selection and link handling

  -- Editing Modules
  "keybindings", -- Core pane/tab/nav keybindings

  -- Integration Modules
  "domains",     -- SSH/Docker/Kubernetes domain management

  -- Workflow Modules
  "git",                              -- Git integration (lazygit)
  { name = "workspace", flags = {} }, -- Workspace switching
  "claude",                           -- Claude Code integration
  "kubernetes",                       -- Kubernetes management (k9s)
  "docker",                           -- Docker management (lazydocker)
  "file-manager",                     -- File manager (yazi)
  "media",                            -- Media player (spotify_player)
  "editors",                          -- Editor launchers (helix, cursor)
  "system-monitor",                   -- System monitoring (btm)
}
