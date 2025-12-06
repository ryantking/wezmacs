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

-- Ensure local wezmacs takes precedence over global installation
-- This is critical for testing local changes with `just test`
local function setup_local_wezmacs_path()
  -- Try to get config directory from wezterm (available after require)
  local config_dir = wezterm.config_dir
  
  -- If config_dir is available, check for local wezmacs
  if config_dir then
    local local_wezmacs_path = config_dir .. "/wezmacs"
    local file = io.open(local_wezmacs_path .. "/init.lua", "r")
    if file then
      file:close()
      -- Prepend local wezmacs to package.path so it takes precedence
      -- Escape special characters for pattern matching
      local escaped_path = local_wezmacs_path:gsub("%-", "%%-")
      package.path = escaped_path .. "/?.lua;" .. escaped_path .. "/?/init.lua;" .. package.path
    end
  end
end

setup_local_wezmacs_path()

local wezmacs = require("wezmacs.init")

-- Create wezterm config
local config = wezterm.config_builder()

-- ============================================================================
-- WEZMACS FRAMEWORK INITIALIZATION
-- ============================================================================
-- Framework auto-discovers modules and loads user config from ~/.config/wezmacs/config.lua

-- Initialize framework
-- Modules are auto-discovered, user config is loaded from ~/.config/wezmacs/config.lua
wezmacs.setup(config, {
  log_level = "info",
})

return config
