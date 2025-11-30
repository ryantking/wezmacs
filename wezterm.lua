--[[
  WezMacs: Modular WezTerm Configuration Framework

  This file serves as the entry point for WezMacs, a Doom Emacs/LazyVim-inspired
  modular configuration system for WezTerm.

  Framework Structure:
  - wezterm.lua: Entry point (this file) at ~/.config/wezterm/
  - wezmacs/init.lua: Framework bootstrap
  - wezmacs/module.lua: Module loading system
  - wezmacs/modules/: Built-in modules (flat structure)

  User Configuration:
  - ~/.config/wezmacs/config.lua: Module selection and flags
  - ~/.config/wezmacs/custom-modules/: User's custom modules
]]

local wezterm = require("wezterm")
local wezmacs = require("wezmacs.init")

-- Create wezterm config
local config = wezterm.config_builder()

-- ============================================================================
-- CORE WEZTERM SETTINGS
-- ============================================================================
-- These settings are applied before framework initialization

-- Terminal protocol support
config.enable_kitty_keyboard = false
config.enable_kitty_graphics = true

-- Shell and workspace defaults
config.default_prog = { "/opt/homebrew/bin/fish", "-l" }
config.default_workspace = "~"

-- ============================================================================
-- WEZMACS FRAMEWORK INITIALIZATION
-- ============================================================================
-- Load user configuration and initialize all modules

wezmacs.setup(config, {
  user_config_path = "user.config",
  log_level = "info",
})

-- ============================================================================
-- GLOBAL EVENT HANDLERS
-- ============================================================================

-- Check if process is stateful (for multiplexing)
wezterm.on("mux-is-process-stateful", function(_proc)
  return false
end)

return config
