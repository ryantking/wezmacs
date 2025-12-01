--[[
  WezMacs Module Loader

  Handles module discovery, loading, and config merging phases.

  Unified config format:
  - Single config.lua contains module configs: {module_name = {key = value, ...}, ...}
  - Module enabled = key exists in config table
  - Feature flags = nested objects within module config
  - Modules use new API: apply_to_config(config) - config accessed via wezmacs.get_config()
]]

local wezterm = require("wezterm")

local M = {}

-- Deep merge two tables, with user values taking precedence
---@param schema table Config schema with default values
---@param user_config table User-provided configuration
---@return table Merged configuration
function M.deep_merge(schema, user_config)
  local result = {}

  -- Copy all schema keys
  for k, v in pairs(schema) do
    if type(v) == "table" and type(user_config[k]) == "table" then
      -- Recursive merge for nested tables
      result[k] = M.deep_merge(v, user_config[k])
    else
      -- Use user value if present, otherwise use schema default
      result[k] = user_config[k] ~= nil and user_config[k] or v
    end
  end

  -- Add any user keys not in schema
  for k, v in pairs(user_config) do
    if result[k] == nil then
      result[k] = v
    end
  end

  return result
end


-- Load all modules based on unified config
---@param unified_config table Unified config table where keys are module names
---@param log function Logging function
---@return table, table Loaded modules (flat array), states with merged configs
function M.load_all(unified_config, log)
  local modules = {}
  local states = {}

  -- Process each module in the config
  for mod_name, mod_user_config in pairs(unified_config) do
    -- Skip if not a table (invalid config)
    if type(mod_user_config) ~= "table" then
      log("warn", "Invalid config for module '" .. mod_name .. "' (must be a table)")
      goto continue
    end

    -- Load the module
    local mod = M.load_module(mod_name, log)
    if mod then
      -- Separate feature flags from regular config
      -- Feature flags are keys defined in mod._FEATURES
      local regular_config = {}
      local feature_flags = {}

      -- Build set of feature flag names for quick lookup
      local feature_names = {}
      for _, feature_item in ipairs(mod._FEATURES or {}) do
        local fname = type(feature_item) == "string" and feature_item or feature_item.name
        if fname then
          feature_names[fname] = true
        end
      end

      -- Separate user config into regular config and feature flags
      for k, v in pairs(mod_user_config) do
        if feature_names[k] then
          feature_flags[k] = v
        else
          regular_config[k] = v
        end
      end

      -- Merge module-level config with schema defaults
      local merged_config = M.merge_config(mod._CONFIG_SCHEMA or {}, regular_config)

      -- Parse features and merge feature configs
      local feature_configs, enabled_flags_array = M.parse_features(
        mod._FEATURES or {},
        feature_flags,
        log
      )

      -- Add features to merged config
      merged_config.features = feature_configs

      -- Store module and state
      states[mod_name] = {
        config = merged_config,
        enabled_flags = enabled_flags_array
      }
      table.insert(modules, mod)

      log("info", "Loaded module: " .. mod_name .. " with " .. #enabled_flags_array .. " feature flags")
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
