--[[
  WezMacs Unified Configuration

  This file contains ALL module configuration in one place.
  - Module enabled = key exists in this table
  - Feature flags = nested objects within module config
  - Empty table {} enables module with defaults

  Example:
    appearance = {
      theme = "TokyoNight",
      ligatures = {},  -- Enable ligatures feature flag
    }
]]

return {
  -- Core WezTerm Settings (applied first)
  core = {
    enable_kitty_keyboard = false,
    enable_kitty_graphics = true,
    default_prog = { "/opt/homebrew/bin/fish", "-l" },
    default_workspace = "~",
  },

  -- UI Modules
  theme = {
    -- Color scheme (nil = use WezTerm default)
    -- Uncomment to customize:
    -- color_scheme = "Horizon Dark (Gogh)",
  },

  fonts = {
    -- All options default to nil (use WezTerm defaults)
    -- Uncomment to customize:
    -- font = "Iosevka Mono",
    -- font_size = 16,
    -- font_rules = nil,  -- nil = auto-generate, {} = disable, [...] = custom
    -- ui_font = "Iosevka",
    -- ui_font_size = 14,

    -- Feature flags:
    -- ligatures = {},  -- Enable font ligatures
  },

  tabbar = {
    -- Custom tab bar with icons
  },

  window = {
    -- Window decorations, padding, scrolling, behavior
    -- Uncomment to customize:
    -- decorations = "RESIZE",
    -- padding = 16,
    -- scrollback_lines = 5000,
  },

  -- Behavior Modules
  mouse = {
    -- Mouse selection and link handling
  },

  -- Editing Modules
  keybindings = {
    leader_key = "Space",
    leader_mod = "CMD",
  },

  -- Workflow Modules
  git = {
    leader_key = "g",
    leader_mod = "LEADER",
    -- Feature flags:
    -- riff = {},  -- Enable riff integration
  },

  workspace = {
    leader_key = "s",
    leader_mod = "LEADER",
  },

  claude = {
    leader_key = "c",
    leader_mod = "LEADER",
  },

  -- Tool Modules
  kubernetes = {
    leader_key = "k",
    leader_mod = "LEADER",
  },

  docker = {
    leader_key = "d",
    leader_mod = "LEADER",
  },

  ["file-manager"] = {
    leader_key = "f",
    leader_mod = "LEADER",
    -- manager = "yazi",  -- File manager to use (default: yazi)
  },

  media = {
    leader_key = "m",
    leader_mod = "LEADER",
  },

  editors = {
    -- terminal_editor = "vim",  -- Default terminal editor
    -- ide = "code",              -- Default IDE (VS Code)
    leader_key = "e",
    leader_mod = "LEADER",
  },

  ["system-monitor"] = {
    leader_key = "h",
    leader_mod = "LEADER",
  },

  -- Integration Modules
  domains = {
    leader_key = "t",
    leader_mod = "LEADER",
  },
}
