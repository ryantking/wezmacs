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
-- Load user configuration from ~/.config/wezmacs/

local function load_config_file(filename)
  local config_dir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local file_path = config_dir .. "/wezmacs/" .. filename

  if wezterm.path_exists(file_path) then
    local chunk, err = loadfile(file_path)
    if chunk then
      return chunk()
    else
      wezterm.log_error("Failed to load " .. filename .. ": " .. err)
      return nil
    end
  else
    wezterm.log_warn(filename .. " not found at " .. file_path)
    return nil
  end
end

-- Load modules specification (which modules to load + feature flags)
local modules_spec = load_config_file("modules.lua")
if not modules_spec then
  wezterm.log_warn("Using default modules - run 'just install' to set up")
  -- Default modules if none specified
  modules_spec = {
    "appearance",
    "tabbar",
    "mouse",
    "keybindings",
    "git",
    "workspace",
    "claude",
  }
end

-- Load user configuration (per-module settings)
local user_config = load_config_file("config.lua") or {}

wezmacs.setup(config, {
  modules_spec = modules_spec,
  user_config = user_config,
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
