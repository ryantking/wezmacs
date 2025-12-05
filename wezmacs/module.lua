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

-- Default load order (can be overridden by user via _load_order in config)
-- Ensures deterministic module loading to prevent keybinding conflicts
local DEFAULT_LOAD_ORDER = {
  "core",        -- Must be first (base settings)
  "theme",       -- Visual settings early
  "keybindings", -- Core keybindings before modules that extend them
  "workspace",   -- Workspace management
  "git",
  "claude",
  "docker",
  "file-manager",
  "editors",
  "domains",
  "kubernetes",
  "media",
  "mouse",
  "system-monitor",
  "tabbar",
  "window",
}

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

  -- Extract user-defined load order if present
  local user_load_order = unified_config._load_order
  local load_order = user_load_order or DEFAULT_LOAD_ORDER

  -- Build ordered list: explicit order first, then remaining modules
  local ordered_modules = {}
  local seen = {}

  -- Add modules in explicit order
  for _, mod_name in ipairs(load_order) do
    if unified_config[mod_name] then
      table.insert(ordered_modules, mod_name)
      seen[mod_name] = true
    end
  end

  -- Add any remaining modules not in explicit order
  for mod_name, _ in pairs(unified_config) do
    if mod_name ~= "_load_order" and not seen[mod_name] then
      table.insert(ordered_modules, mod_name)
    end
  end

  -- Load modules in deterministic order
  for _, mod_name in ipairs(ordered_modules) do
    local mod_user_config = unified_config[mod_name]

    if type(mod_user_config) ~= "table" then
      log("warn", "Invalid config for module '" .. mod_name .. "' (must be a table)")
      goto continue
    end

    local mod = M.load_module(mod_name, log)
    if mod then
      -- Validate module has _CONFIG
      if not mod._CONFIG then
        log("error", "Module '" .. mod_name .. "' missing required '_CONFIG' definition")
        goto continue
      end

      -- Deep merge user config with module _CONFIG defaults
      local merged_config = M.deep_merge(mod._CONFIG, mod_user_config)

      -- Store module and state
      states[mod_name] = merged_config
      table.insert(modules, mod)

      log("info", "Loaded module: " .. mod_name)
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
