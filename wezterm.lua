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
  - ~/.config/wezmacs/config.lua: Unified module configuration
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
-- Load unified configuration from ~/.config/wezmacs/config.lua

local function load_unified_config()
  local config_dir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local file_path = config_dir .. "/wezmacs/config.lua"

  if wezterm.path_exists(file_path) then
    local chunk, err = loadfile(file_path)
    if chunk then
      return chunk()
    else
      wezterm.log_error("Failed to load config.lua: " .. err)
      return nil
    end
  else
    wezterm.log_warn("config.lua not found at " .. file_path)
    return nil
  end
end

-- Load unified config
local unified_config = load_unified_config()
if not unified_config then
  wezterm.log_warn("Using default modules - run 'just install' to set up")
  -- Default configuration if none specified
  unified_config = {
    appearance = {},
    tabbar = {},
    mouse = {},
    keybindings = {
      leader_key = "Space",
      leader_mod = "CMD",
    },
    git = {},
    workspace = {},
    claude = {},
  }
end

wezmacs.setup(config, {
  unified_config = unified_config,
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
