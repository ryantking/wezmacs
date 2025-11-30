--[[
  WezMacs Module Loader

  Handles module discovery, loading, initialization, and application phases.

  New module format:
  - modules.lua contains array of module specs: "module-name" or {name="module-name", flags={...}}
  - config.lua contains module configuration: {module_name = {key = value, ...}, ...}
  - Modules have new API: init(enabled_flags, user_config, log), apply_to_config(config, state)
]]

local wezterm = require("wezterm")

local M = {}

-- Load all modules based on module specification array
---@param modules_spec table Module specification array: "name" or {name="name", flags={...}}
---@param user_config table Per-module configuration from config.lua
---@param log function Logging function
---@return table, table Loaded modules (flat array), states from init phase
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
      local mod_config = user_config[mod_name] or {}

      -- Run init phase if it exists
      local state = {}
      if mod.init then
        state = mod.init(enabled_flags, mod_config, log) or {}
      end

      -- Store module and state
      states[mod_name] = state
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
