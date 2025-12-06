--[[
  WezMacs Module Loader

  Handles module discovery, loading, and config merging phases.
  LazyVim-style: init.lua returns spec table directly.

  Unified config format:
  - Single config.lua contains module configs: {module_name = {key = value, ...}, ...}
  - Module enabled = key exists in config table
  - Feature flags = nested objects within module config
  - Modules use new API: apply_to_config(config, opts) - config accessed via wezmacs.get_module()
]]

local registry = require("wezmacs.lib.registry")
local config_lib = require("wezmacs.lib.config")

local M = {}


-- Discover all module specs (new format)
---@param log function Logging function
function M.discover_modules(log)
  local module_dirs = {
    "wezmacs.modules",  -- Built-in modules
    "user.custom-modules",  -- User custom modules
  }

  local specs = {}

  for _, base_path in ipairs(module_dirs) do
    -- Use Lua's package system to discover modules
    -- LazyVim-style: init.lua returns spec table directly
    -- We'll discover specs when modules are loaded
    -- This is simpler than trying to scan directories
  end

  return specs
end

-- Load a single module (LazyVim-style: single file returns spec table)
---@param mod_name string Module name
---@param log function Logging function
---@return table|nil Loaded module spec or nil if failed
function M.load_module(mod_name, log)
  -- Load module (single file returns spec table directly)
  -- Try: wezmacs.modules.git (for modules/git.lua)
  local require_path = "wezmacs.modules." .. mod_name
  local ok, spec = pcall(require, require_path)

  -- If not found in built-in, try custom modules
  if not ok then
    require_path = "user.custom-modules." .. mod_name
    ok, spec = pcall(require, require_path)
  end

  if not ok then
    log("error", "Failed to load module '" .. mod_name .. "': " .. tostring(spec))
    return nil
  end

  if type(spec) ~= "table" then
    log("error", "Module '" .. mod_name .. "' must return a spec table")
    return nil
  end

  -- Validate spec has required fields
  if not spec.name then
    spec.name = mod_name  -- Use directory name as fallback
    log("warn", "Module '" .. mod_name .. "' spec missing 'name' field, using directory name")
  end

  if not spec.apply_to_config then
    log("error", "Module '" .. mod_name .. "' spec missing required 'apply_to_config' function")
    return nil
  end

  -- Register spec
  registry.register(spec)
  log("info", "Registered spec for module: " .. spec.name)

  return spec
end

-- Load all modules based on unified config
---@param unified_config table Unified config table where keys are module names
---@param log function Logging function
---@return table, table Loaded modules (flat array), states with merged configs
function M.load_all(unified_config, log)
  local modules = {}
  local states = {}

  log("info", "Discovering modules...")
  
  -- Collect module names from config
  local module_names = {}
  for mod_name, _ in pairs(unified_config) do
    if mod_name ~= "_load_order" then
      table.insert(module_names, mod_name)
    end
  end

  -- Pre-load all modules to register their specs (for dependency resolution)
  for _, mod_name in ipairs(module_names) do
    local spec = M.load_module(mod_name, log)
    -- Don't store yet, just register for dependency resolution
  end

  -- Resolve load order using registry (dependency-based)
  local load_order = registry.resolve_load_order(module_names)

  log("info", "Load order: " .. table.concat(load_order, " -> "))

  -- Load modules in resolved order (reload to get fresh spec)
  for _, mod_name in ipairs(load_order) do
    local mod_user_config = unified_config[mod_name] or {}

    if type(mod_user_config) ~= "table" then
      log("warn", "Invalid config for module '" .. mod_name .. "' (must be a table)")
      goto continue
    end

    -- Reload module to get fresh spec (package.loaded cache might have old version)
    package.loaded["wezmacs.modules." .. mod_name] = nil
    package.loaded["user.custom-modules." .. mod_name] = nil
    
    local spec = M.load_module(mod_name, log)
    if not spec then
      goto continue
    end

    -- Check if module is enabled
    local is_enabled = config_lib.is_enabled(spec, mod_user_config)
    if not is_enabled then
      log("info", "Module disabled: " .. mod_name)
      goto continue
    end

    -- Validate dependencies
    local deps_ok, missing = registry.validate_dependencies(spec)
    if not deps_ok then
      log("warn", "Module " .. mod_name .. " missing dependencies: " .. table.concat(missing, ", "))
      -- Continue anyway (graceful degradation)
    end

    -- Deep merge user config with defaults
    local merged_config = config_lib.deep_merge(spec.opts or {}, mod_user_config)

    -- Store module spec and state
    states[mod_name] = merged_config
    table.insert(modules, spec)
    registry.mark_loaded(mod_name)

    log("info", "Loaded module: " .. mod_name)
    ::continue::
  end

  return modules, states
end

return M
