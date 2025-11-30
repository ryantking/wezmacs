--[[
  WezMacs Module Loader

  Handles module discovery, loading, initialization, and application phases.
]]

local wezterm = require("wezterm")

local M = {}

-- Load all modules based on module specification
---@param config table WezTerm config object
---@param module_spec table Module specification { category = { "module1", "module2" }, ... }
---@param flags table Feature flags per category
---@param log function Logging function
---@return table, table Modules organized by category, states from init phase
function M.load_all(config, module_spec, flags, log)
  local modules = {}
  local states = {}

  -- Process each category of modules
  for category, mod_names in pairs(module_spec) do
    modules[category] = {}

    -- Handle both string and array formats
    local names_to_load = mod_names
    if type(mod_names) == "string" then
      names_to_load = { mod_names }
    end

    -- Load each module in the category
    for _, mod_name in ipairs(names_to_load) do
      -- Skip if module name is explicitly disabled (via table with enabled=false)
      if mod_names[mod_name] == false then
        goto continue
      end

      local mod = M.load_module(config, category, mod_name, log)
      if mod then
        -- Run init phase if it exists
        local state = {}
        if mod.init then
          local category_flags = flags[category] or {}
          state = mod.init(category_flags, log) or {}
        end

        -- Store module and state
        local mod_key = mod._NAME or mod_name
        states[mod_key] = state
        table.insert(modules[category], mod)
      end

      ::continue::
    end
  end

  return modules, states
end

-- Load a single module
---@param config table WezTerm config object
---@param category string Module category (ui, behavior, editing, etc)
---@param mod_name string Module name
---@param log function Logging function
---@return table|nil Loaded module or nil if failed
function M.load_module(config, category, mod_name, log)
  -- Build the require path - modules are now flat under wezmacs/modules/
  local require_path = "wezmacs.modules." .. mod_name
  local alt_require_path = "user.custom-modules." .. mod_name

  local ok, mod = pcall(require, require_path)

  -- If not found in built-in modules, try custom modules
  if not ok then
    ok, mod = pcall(require, alt_require_path)
  end

  if not ok then
    log("error", "Failed to load module '" .. mod_name .. "' from category '" .. category .. "': " .. tostring(mod))
    return nil
  end

  -- Validate module has required interface
  if not mod.apply_to_config then
    log("error", "Module '" .. mod_name .. "' missing required 'apply_to_config' function")
    return nil
  end

  return mod
end

-- Discover available modules (for documentation/diagnostics)
---@return table Organized list of available modules
function M.discover_modules()
  local categories = { "ui", "behavior", "editing", "integration", "workflows" }
  local available = {}

  for _, category in ipairs(categories) do
    available[category] = {}
    local category_path = "wezmacs/categories/" .. category
    -- Note: In Lua, directory scanning requires OS support
    -- For now, this is a placeholder for future enhancement
  end

  return available
end

return M
