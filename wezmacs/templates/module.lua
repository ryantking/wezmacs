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

-- Define configurable flags (schema)
M._FLAGS_SCHEMA = {
  -- example_flag = "string or number or table",  -- description
}

-- ============================================================================
-- INIT PHASE (Optional)
-- ============================================================================
-- Called during framework initialization to set up module state.
-- Use this to:
--   - Validate configuration flags
--   - Perform early setup that might fail
--   - Compute derived values from flags
--
-- Return a table with state that will be passed to apply_to_config.
-- If you don't need this phase, simply delete this function.

function M.init(flags, log)
  -- flags: table of configuration for this module category
  -- log: function(msg) for logging info/debug messages

  log("Initializing " .. M._NAME .. " module")

  -- Example: validate and store flags
  return {
    -- Your computed state here
    -- e.g., leader_key = flags.leader_key or "Space",
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
