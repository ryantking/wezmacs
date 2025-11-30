--[[
  WezMacs Module Loader

  Handles module discovery, loading, and config merging phases.

  New module format:
  - modules.lua contains array of module specs: "module-name" or {name="module-name", flags={...}}
  - config.lua contains module configuration: {module_name = {key = value, ...}, ...}
  - Modules use new API: apply_to_config(config) - config accessed via wezmacs.get_config()
]]

local wezterm = require("wezterm")

local M = {}

-- Merge user config with schema defaults
---@param schema table Config schema with default values
---@param user_config table User-provided configuration
---@return table Merged configuration
function M.merge_config(schema, user_config)
  local config = {}
  for k, v in pairs(schema) do
    config[k] = user_config[k] ~= nil and user_config[k] or v
  end
  return config
end

-- Parse _FEATURES format and merge feature configs
---@param features_def table Features definition (array of strings and objects)
---@param enabled_flags table Array of enabled feature flag names
---@param user_config table User-provided configuration
---@return table, table Merged feature configs and enabled flags array
function M.parse_features(features_def, enabled_flags, user_config)
  local feature_configs = {}
  local enabled_flags_array = {}

  for _, feature in ipairs(enabled_flags) do
    table.insert(enabled_flags_array, feature)
  end

  for _, feature_item in ipairs(features_def or {}) do
    if type(feature_item) == "string" then
      -- Simple flag: just track if enabled
      for _, enabled in ipairs(enabled_flags) do
        if enabled == feature_item then
          feature_configs[feature_item] = true
          break
        end
      end
    elseif type(feature_item) == "table" and feature_item.name then
      -- Complex feature: merge config
      local feature_name = feature_item.name
      local is_enabled = false

      for _, enabled in ipairs(enabled_flags) do
        if enabled == feature_name then
          is_enabled = true
          break
        end
      end

      if is_enabled then
        local feature_user_config = user_config[feature_name] or {}
        local merged = M.merge_config(feature_item.config_schema or {}, feature_user_config)
        feature_configs[feature_name] = merged
      end
    end
  end

  return feature_configs, enabled_flags_array
end

-- Load all modules based on module specification array
---@param modules_spec table Module specification array: "name" or {name="name", flags={...}}
---@param user_config table Per-module configuration from config.lua
---@param log function Logging function
---@return table, table Loaded modules (flat array), states with merged configs
function M.load_all(modules_spec, user_config, log)
  local modules = {}
  local states = {}

  -- Process each module specification
  for _, spec in ipairs(modules_spec) do
    -- Parse spec: can be string or {name=..., flags=...}
    local mod_name, enabled_flags
    if type(spec) == "string" then
      mod_name = spec
      enabled_flags = {}
    elseif type(spec) == "table" and spec.name then
      mod_name = spec.name
      enabled_flags = spec.flags or {}
    else
      log("warn", "Invalid module spec format: " .. tostring(spec))
      goto continue
    end

    -- Load the module
    local mod = M.load_module(mod_name, log)
    if mod then
      -- Extract config for this specific module
      local mod_user_config = user_config[mod_name] or {}

      -- Merge module-level config
      local merged_config = M.merge_config(mod._CONFIG_SCHEMA or {}, mod_user_config)

      -- Parse features and merge feature configs
      local feature_configs, enabled_flags_array = M.parse_features(
        mod._FEATURES or {},
        enabled_flags,
        mod_user_config.features or {}
      )

      -- Add features to merged config
      merged_config.features = feature_configs

      -- Store module and state (no longer running init())
      states[mod_name] = {
        config = merged_config,
        enabled_flags = enabled_flags_array
      }
      table.insert(modules, mod)
    end

    ::continue::
  end

  return modules, states
end

-- Load a single module by name
---@param mod_name string Module name
---@param log function Logging function
---@return table|nil Loaded module or nil if failed
function M.load_module(mod_name, log)
  -- Try built-in modules first (flat structure under wezmacs/modules/)
  local require_path = "wezmacs.modules." .. mod_name
  local ok, mod = pcall(require, require_path)

  -- If not found in built-in, try custom modules
  if not ok then
    require_path = "user.custom-modules." .. mod_name
    ok, mod = pcall(require, require_path)
  end

  if not ok then
    log("error", "Failed to load module '" .. mod_name .. "': " .. tostring(mod))
    return nil
  end

  -- Validate module has required interface
  if not mod.apply_to_config then
    log("error", "Module '" .. mod_name .. "' missing required 'apply_to_config' function")
    return nil
  end

  if not mod._NAME then
    log("warn", "Module '" .. mod_name .. "' missing '_NAME' metadata")
  end

  return mod
end

return M
