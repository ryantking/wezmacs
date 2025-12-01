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
      error("Failed to load config.lua: " .. err)
    end
  else
    return nil
  end
end

-- Load unified config or fail
local unified_config = load_unified_config()
if not unified_config then
  error("WezMacs config not found at ~/.config/wezmacs/config.lua\nRun 'just init' to create configuration")
end

-- Initialize framework (core module will handle core settings)
wezmacs.setup(config, {
  unified_config = unified_config,
  log_level = "info",
})

return config
