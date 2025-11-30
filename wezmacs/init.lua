--[[
  WezMacs Framework Bootstrap

  Main entry point for the WezMacs modular wezterm configuration framework.
  Orchestrates module loading, configuration merging, and initialization.
]]

local wezterm = require("wezterm")
local module_loader = require("wezmacs.module")

local M = {}

-- Main setup function called from wezterm.lua
---@param config table WezTerm config object from config_builder()
---@param opts table Optional configuration options
function M.setup(config, opts)
  opts = opts or {}

  -- Setup logging function
  local log_level = opts.log_level or "info"
  local function log(level, msg)
    local prefix = "[WezMacs] "
    if level == "error" then
      wezterm.log_error(prefix .. msg)
    elseif level == "warn" then
      wezterm.log_info(prefix .. "WARN: " .. msg)
    elseif level ~= "debug" or log_level == "debug" then
      wezterm.log_info(prefix .. msg)
    end
  end

  -- Use provided modules list and user_config or empty table as fallback
  local modules_spec = opts.modules_spec or {}
  local user_config = opts.user_config or {}

  log("info", "Loading WezMacs framework")

  -- Phase 1: Load and initialize all modules (init phase)
  local modules, states = module_loader.load_all(
    modules_spec,
    user_config,
    log
  )

  -- Phase 2: Apply all modules to config (apply_to_config phase)
  for _, mod in ipairs(modules) do
    local mod_name = mod._NAME or "unknown"
    log("info", "Applying module: " .. mod_name)

    -- Call apply_to_config with config and state from init
    if mod.apply_to_config then
      mod.apply_to_config(config, states[mod_name] or {})
    end
  end

  log("info", "WezMacs framework initialized successfully")
end

-- Get default configuration (all modules enabled)
---@return table Default configuration
function M.default_config()
  return {
    modules = {
      ui = { "appearance", "tabbar" },
      behavior = { "mouse" },
      editing = { "keybindings" },
      workflows = { "git", "workspace", "claude" },
    },
    flags = {},
    overrides = nil,
  }
end

-- Deep merge two configuration tables
-- User config takes precedence over defaults
---@param defaults table Default configuration
---@param user table User configuration
---@return table Merged configuration
function M.merge_configs(defaults, user)
  local merged = {}

  -- Merge module lists (user can override or extend)
  merged.modules = {}
  if defaults.modules then
    for category, mods in pairs(defaults.modules) do
      merged.modules[category] = mods
    end
  end
  if user.modules then
    for category, mods in pairs(user.modules) do
      merged.modules[category] = mods
    end
  end

  -- Deep merge flags (combine from both)
  merged.flags = {}
  if defaults.flags then
    for category, flags_tbl in pairs(defaults.flags) do
      merged.flags[category] = {}
      for key, value in pairs(flags_tbl) do
        merged.flags[category][key] = value
      end
    end
  end
  if user.flags then
    for category, flags_tbl in pairs(user.flags) do
      if not merged.flags[category] then
        merged.flags[category] = {}
      end
      for key, value in pairs(flags_tbl) do
        merged.flags[category][key] = value
      end
    end
  end

  -- User overrides function
  merged.overrides = user.overrides

  return merged
end

return M
