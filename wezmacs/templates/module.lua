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
M._DESCRIPTION = "Brief description of what this module does"

-- External dependencies that should be documented for users
-- Use for module-level deps (tools always needed if module is loaded)
M._EXTERNAL_DEPS = {
  -- "lazygit",  -- Example: tool name
  -- "git",      -- Example: tool name
}

-- Features: optional features users can enable in modules.lua
-- Example: { name = "your-module-name", flags = { "riff" } }
-- Or with complex config/deps: { name = "your-module-name", flags = { { name = "riff", deps = {"riff"} } } }
M._FEATURES = {
  -- "simple_flag",           -- Example: simple boolean feature flag
  -- {
  --   name = "complex_flag",
  --   config_schema = { option = "default" },  -- Feature-specific config defaults
  --   deps = { "external_tool" }               -- Feature-specific dependencies
  -- }
}

-- Configuration schema: default values for all configuration options
-- Users can override these in config.lua
M._CONFIG_SCHEMA = {
  -- leader_key = "y",        -- Example: default keybinding
  -- leader_mod = "LEADER",   -- Example: default modifier
  -- timeout = 5000,          -- Example: default timeout in ms
}

-- ============================================================================
-- APPLY PHASE (Required)
-- ============================================================================
-- Called after all modules are initialized with merged configs.
-- Apply your configuration to the wezterm config object here.
--
-- Parameters:
--   config: WezTerm config object (from config_builder())
--
-- Access your module's config:
--   - local mod_config = wezmacs.get_config(M._NAME)
--   - Access module config: mod_config.leader_key
--   - Access feature config: mod_config.features.feature_name
--   - Access enabled flags: wezmacs.get_enabled_flags(M._NAME)

function M.apply_to_config(config)
  -- Get this module's configuration (framework handles merging)
  local mod_config = wezmacs.get_config(M._NAME)
  local enabled_flags = wezmacs.get_enabled_flags(M._NAME)

  -- Example: Check for enabled feature flags
  -- for _, flag in ipairs(enabled_flags) do
  --   if flag == "simple_flag" then
  --     -- Enable simple-flag functionality
  --   end
  -- end

  -- Example: Access feature config
  -- if mod_config.features.complex_flag then
  --   local feat_config = mod_config.features.complex_flag
  --   -- Use feat_config.option
  -- end

  -- Example: Apply a keybinding using configuration values
  -- config.keys = config.keys or {}
  -- table.insert(config.keys, {
  --   key = mod_config.leader_key,
  --   mods = mod_config.leader_mod,
  --   action = wezterm.action.ActivateKeyTable({
  --     name = "your-module",
  --     one_shot = false,
  --     until_unknown = true,
  --   }),
  -- })

  -- Example: Create a key table
  -- config.key_tables = config.key_tables or {}
  -- config.key_tables["your-module"] = {
  --   { key = "a", action = wezterm.action.SomeAction() },
  --   { key = "b", action = wezterm.action.OtherAction() },
  --   { key = "Escape", action = "PopKeyTable" },
  -- }

  -- Example: Register an event handler
  -- wezterm.on("your-module-event", function(window, pane)
  --   window:toast_notification("WezMacs", "Event fired!", nil, 3000)
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
