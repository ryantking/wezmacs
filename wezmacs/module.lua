--[[
  WezMacs Module Loader

  Handles module discovery, loading, and config merging.
  LazyVim-style: modules return spec tables that get merged with user config.
]]

local registry = require("wezmacs.lib.registry")
local config_lib = require("wezmacs.lib.config")

local M = {}

-- Discover all built-in modules
---@param log function Logging function
---@return table Array of module names
local function discover_builtin_modules(log)
  -- Hardcode known modules (we can scan directory later if needed)
  local known_modules = {
    "core", "keybindings", "theme", "git", "claude", "docker", "editors",
    "file-manager", "kubernetes", "media", "system-monitor", "domains",
    "workspace", "window", "tabbar", "mouse", "fonts"
  }
  
  local modules = {}
  for _, mod_name in ipairs(known_modules) do
    local ok, _ = pcall(require, "wezmacs.modules." .. mod_name)
    if ok then
      table.insert(modules, mod_name)
    else
      log("warn", "Could not load module: " .. mod_name)
    end
  end
  
  return modules
end

-- Load a single module (supports both module.lua and module/init.lua)
---@param mod_name string Module name
---@param log function Logging function
---@return table|nil Loaded module spec or nil if failed
function M.load_module(mod_name, log)
  -- Try module.lua first (flat structure)
  local require_path = "wezmacs.modules." .. mod_name
  local ok, spec = pcall(require, require_path)

  -- If not found, try module/init.lua (nested structure)
  if not ok then
    require_path = "wezmacs.modules." .. mod_name .. ".init"
    ok, spec = pcall(require, require_path)
  end

  -- If not found in built-in, try user custom modules
  if not ok then
    require_path = "user.modules." .. mod_name
    ok, spec = pcall(require, require_path)
    if not ok then
      require_path = "user.modules." .. mod_name .. ".init"
      ok, spec = pcall(require, require_path)
    end
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

  if not spec.setup then
    log("error", "Module '" .. mod_name .. "' spec missing required 'setup' function")
    return nil
  end

  if not spec.opts or type(spec.opts) ~= "function" then
    log("warn", "Module '" .. mod_name .. "' spec missing 'opts' function, using empty defaults")
    spec.opts = function() return {} end
  end

  -- Default enabled to true if not specified
  if spec.enabled == nil then
    spec.enabled = true
  end

  -- Register spec
  registry.register(spec)
  log("info", "Registered spec for module: " .. spec.name)

  return spec
end

-- Merge user config overrides into module specs
---@param specs table Map of module name -> spec
---@param user_config table User config list (e.g., { { "claude", enabled = false } })
---@param log function Logging function
local function merge_user_config(specs, user_config, log)
  if not user_config or type(user_config) ~= "table" then
    return
  end

  for _, override in ipairs(user_config) do
    if type(override) == "table" then
      local mod_name = override[1] or override.name
      if not mod_name then
        log("warn", "User config entry missing module name")
        goto continue
      end

      local spec = specs[mod_name]
      if not spec then
        log("warn", "User config references unknown module: " .. mod_name)
        goto continue
      end

      -- Merge override into spec (deep merge for opts, override for other fields)
      for key, value in pairs(override) do
        if key ~= 1 and key ~= "name" then  -- Skip array index and name
          if key == "opts" and type(value) == "table" then
            -- Deep merge opts
            local default_opts = spec.opts()
            spec.opts = function()
              return config_lib.deep_merge(default_opts, value)
            end
          elseif key == "opts" and type(value) == "function" then
            -- Function opts - wrap to merge
            local default_opts_fn = spec.opts
            spec.opts = function()
              local default_opts = default_opts_fn()
              return value(default_opts)
            end
          else
            -- Override other fields (enabled, priority, etc.)
            spec[key] = value
          end
        end
      end

      ::continue::
    end
  end
end

-- Load all modules and merge with user config
---@param log function Logging function
---@return table Array of enabled module specs
function M.load_all(log)
  log("info", "Discovering modules...")
  
  -- Discover all built-in modules
  local module_names = discover_builtin_modules(log)
  
  -- Load all module specs
  local specs = {}
  for _, mod_name in ipairs(module_names) do
    local spec = M.load_module(mod_name, log)
    if spec then
      specs[mod_name] = spec
    end
  end

  -- Load user custom modules from ~/.config/wezmacs/modules/
  -- (if directory exists and has .lua files)
  local user_modules_path = (os.getenv("HOME") or "") .. "/.config/wezmacs/modules"
  -- TODO: Scan user_modules_path for .lua files and load them
  
  -- Load user config from ~/.config/wezmacs/config.lua
  local user_config = nil
  local home = os.getenv("HOME") or ""
  local user_config_path = home .. "/.config/wezmacs/config.lua"
  
  local ok, result = pcall(function()
    -- Check if file exists
    local file = io.open(user_config_path, "r")
    if not file then
      return nil
    end
    file:close()
    
    -- Load file using loadfile
    local chunk, err = loadfile(user_config_path)
    if not chunk then
      log("error", "Failed to load user config: " .. tostring(err))
      return nil
    end
    
    -- Setup package.path for any requires in user config
    local old_path = package.path
    package.path = home .. "/.config/wezmacs/?.lua;" .. package.path
    
    -- Execute chunk
    local success, user_config_module = pcall(chunk)
    package.path = old_path
    
    if success and user_config_module then
      return user_config_module
    end
    return nil
  end)
  
  if ok and result then
    user_config = result
    log("info", "Loaded user config from ~/.config/wezmacs/config.lua")
  else
    log("info", "No user config found at ~/.config/wezmacs/config.lua (this is optional)")
  end

  -- Merge user config overrides
  if user_config then
    merge_user_config(specs, user_config, log)
  end

  -- Filter enabled modules and resolve load order
  local enabled_modules = {}
  for mod_name, spec in pairs(specs) do
    -- Check if module is enabled
    local is_enabled = true
    if type(spec.enabled) == "function" then
      local ctx = {
        has_command = function(cmd)
          return registry.has_command(cmd)
        end,
      }
      is_enabled = spec.enabled(ctx)
    elseif spec.enabled ~= nil then
      is_enabled = spec.enabled
    end

    if is_enabled then
      table.insert(enabled_modules, mod_name)
    else
      log("info", "Module disabled: " .. mod_name)
    end
  end

  -- Resolve load order
  local load_order = registry.resolve_load_order(enabled_modules)
  log("info", "Load order: " .. table.concat(load_order, " -> "))

  -- Return specs in load order
  local ordered_specs = {}
  for _, mod_name in ipairs(load_order) do
    table.insert(ordered_specs, specs[mod_name])
  end

  return ordered_specs, specs
end

return M
