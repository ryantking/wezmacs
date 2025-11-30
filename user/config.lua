--[[
  WezMacs User Configuration

  This file contains PER-MODULE CONFIGURATION (values and options).

  Module selection and feature flags are specified in modules.lua.
  This file specifies HOW each module should be configured.

  Example:
  ```lua
  appearance = {
    theme = "Horizon Dark (Gogh)",
    font = "JetBrains Mono",
    font_size = 16,
  },
  git = {
    leader_key = "g",
    leader_mod = "LEADER",
  },
  ```
]]

return {
  -- Appearance module configuration
  appearance = {
    theme = "Horizon Dark (Gogh)",  -- WezTerm builtin color scheme
    font = "Iosevka Mono",
    font_size = 16,
  },

  -- Keybindings module configuration
  keybindings = {
    leader_key = "Space",
    leader_mod = "CMD",
  },

  -- Git module configuration
  git = {
    leader_key = "g",
    leader_mod = "LEADER",
  },

  -- Workspace module configuration
  workspace = {
    leader_key = "s",
    leader_mod = "LEADER",
  },

  -- Claude module configuration
  claude = {
    leader_key = "c",
    leader_mod = "LEADER",
  },

  -- Kubernetes module configuration
  kubernetes = {
    leader_key = "k",
    leader_mod = "LEADER",
  },

  -- Docker module configuration
  docker = {
    leader_key = "D",
    leader_mod = "LEADER",
  },

  -- File manager module configuration
  ["file-manager"] = {
    leader_key = "y",
    leader_mod = "LEADER",
    sudo_key = "Y",
  },

  -- Media module configuration
  media = {
    leader_key = "m",
    leader_mod = "LEADER",
  },

  -- Editors module configuration
  editors = {
    helix_key = "E",
    cursor_key = "C",
    leader_mod = "LEADER",
  },

  -- System monitor module configuration
  ["system-monitor"] = {
    leader_key = "h",
    leader_mod = "LEADER",
  },

  -- Domains module configuration
  domains = {
    attach_key = "t",
    attach_mods = "ALT|SHIFT",
    vsplit_key = "_",
    vsplit_mods = "CTRL|SHIFT|ALT",
    hsplit_key = "-",
    hsplit_mods = "CTRL|ALT",
  },
}
