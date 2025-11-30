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

  -- Use provided user_config or empty table as fallback
  local user_config = opts.user_config or {}

  -- Merge with defaults
  local final_config = M.merge_configs(M.default_config(), user_config)

  log("info", "Loading WezMacs framework")

  -- Phase 1: Load and initialize all modules (init phase)
  local modules, states = module_loader.load_all(
    config,
    final_config.modules,
    final_config.flags,
    log
  )

  -- Phase 2: Apply all modules to config (apply_to_config phase)
  for category, mods in pairs(modules) do
    for _, mod in ipairs(mods) do
      local mod_name = mod._NAME or "unknown"
      log("info", "Applying module: " .. category .. "/" .. mod_name)

      -- Get flags for this module's category
      local category_flags = final_config.flags[category] or {}

      -- Call apply_to_config with config, flags, and state from init
      if mod.apply_to_config then
        mod.apply_to_config(config, category_flags, states[mod_name] or {})
      end
    end
  end

  -- Phase 3: User overrides (final customization)
  if final_config.overrides and type(final_config.overrides) == "function" then
    log("info", "Applying user overrides")
    final_config.overrides(config)
  end

  log("info", "WezMacs framework initialized successfully")
end

-- Load user configuration from user/config.lua
---@param path string Module path to user config (e.g., "user.config")
---@param log function Logging function
---@return table|nil User configuration table or nil if not found
function M.load_user_config(path, log)
  path = path or "user.config"

  local ok, user_config = pcall(require, path)
  if not ok then
    log("warn", "User config not found at '" .. path .. "' - using defaults")
    return nil
  end

  return user_config
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
