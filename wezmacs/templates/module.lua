--[[
  WezMacs Module Template

  Copy this file as a starting point for creating new modules.
  Follow the structure and patterns shown here for consistency.

  Module files should be placed in:
    wezmacs/modules/[module-name]/init.lua

  Where [module-name] is a kebab-case name describing the module.

  Categories (for documentation only):
    - ui: Visual styling, appearance, tabs
    - behavior: User interactions, mouse, scrolling
    - editing: Keybindings, selection, input
    - integration: Plugins, multiplexing, external tools
    - workflows: Feature-specific workflows (git, workspace, etc)

  Or in custom locations:
    ~/.config/wezmacs/custom-modules/[module-name]/init.lua
]]

local wezterm = require("wezterm")
local M = {}

-- ============================================================================
-- MODULE METADATA
-- ============================================================================
-- These fields help the framework understand and manage your module

M._NAME = "your-module-name"
M._CATEGORY = "workflows"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Brief description of what this module does"

-- External dependencies that should be documented for users
M._EXTERNAL_DEPS = {
  -- "lazygit",  -- Example: tool name
  -- "git",      -- Example: tool name
}

-- Feature flags: optional features users can enable in modules.lua
-- Example: { name = "your-module-name", flags = { "smartsplit", "diff-viewer" } }
M._FEATURE_FLAGS = {
  -- "smartsplit",   -- Example: optional smart-split feature
  -- "diff-viewer",  -- Example: optional diff viewer feature
}

-- Configuration schema: default values for all configuration options
-- Users can override these in config.lua
M._CONFIG_SCHEMA = {
  -- leader_key = "y",        -- Example: default keybinding
  -- leader_mod = "LEADER",   -- Example: default modifier
  -- timeout = 5000,          -- Example: default timeout in ms
}

-- ============================================================================
-- INIT PHASE (Optional)
-- ============================================================================
-- Called during framework initialization to merge user config with defaults.
-- Use this to:
--   - Merge user configuration with _CONFIG_SCHEMA defaults
--   - Validate configuration values
--   - Store enabled feature flags for use in apply_to_config
--
-- Parameters:
--   enabled_flags: Array of feature flags from modules.lua
--                  Example: {"smartsplit", "diff-viewer"}
--   user_config: Table of configuration from config.lua
--                Example: {leader_key = "g", timeout = 3000}
--   log: Logging function for info/debug messages
--
-- Return a state table containing merged config and flags.
-- If you don't need this phase, simply delete this function.

function M.init(enabled_flags, user_config, log)
  log("Initializing " .. M._NAME .. " module")

  -- Standard pattern: merge user config with schema defaults
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end

  -- Return state with merged config and enabled flags
  return {
    config = config,
    flags = enabled_flags or {},
  }
end

-- ============================================================================
-- APPLY PHASE (Required)
-- ============================================================================
-- Called after all modules are initialized.
-- Apply your configuration to the wezterm config object here.
--
-- Parameters:
--   config: WezTerm config object (from config_builder())
--   flags: Table of configuration flags for this module's category
--   state: State returned from init() phase (or {} if no init)

function M.apply_to_config(config, flags, state)
  -- Example: Apply a keybinding
  -- config.keys = config.keys or {}
  -- table.insert(config.keys, {
  --   key = "s",
  --   mods = "CMD",
  --   action = wezterm.action.SpawnTab("CurrentPaneDomain"),
  -- })

  -- Example: Create a key table
  -- config.key_tables = config.key_tables or {}
  -- config.key_tables.example = {
  --   { key = "a", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
  --   { key = "Escape", action = "PopKeyTable" },
  -- }

  -- Example: Register an event handler
  -- wezterm.on("example-event", function(window, pane)
  --   window:toast_notification("WezTerm", "Example event fired!", nil, 3000)
  -- end)
end

-- ============================================================================
-- OPTIONAL: PUBLIC API
-- ============================================================================
-- Expose public functions that other modules or user config can call

-- M.public_function = function()
--   return "This can be called from other modules"
-- end

return M
