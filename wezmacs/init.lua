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

  -- Phase 1: Load all modules with config merging (no init() phase)
  local modules, states = module_loader.load_all(
    modules_spec,
    user_config,
    log
  )

  -- Create global wezmacs API table (captured closure over states)
  _G.wezmacs = {
    -- Get merged config for a module
    get_config = function(module_name)
      local state = states[module_name]
      if not state then
        log("warn", "No config found for module: " .. module_name)
        return { features = {} }
      end
      return state.config
    end,

    -- Get enabled flags for a module
    get_enabled_flags = function(module_name)
      local state = states[module_name]
      return state and state.enabled_flags or {}
    end,
  }

  -- Phase 2: Apply all modules to config
  for _, mod in ipairs(modules) do
    local mod_name = mod._NAME or "unknown"
    log("info", "Applying module: " .. mod_name)

    -- Call apply_to_config with only config parameter
    if mod.apply_to_config then
      mod.apply_to_config(config)
    end
  end

  log("info", "WezMacs framework initialized successfully")
end

return M
