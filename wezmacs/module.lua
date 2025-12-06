--[[
  WezMacs Module Loader

  Handles module discovery, loading, and config merging.
  LazyVim-style: modules return spec tables that get merged with user config.
]]

local registry = require("wezmacs.lib.registry")
local config_lib = require("wezmacs.lib.config")

local M = {}

-- Get lua directory (where wezmacs framework is installed)
-- This assumes package.path has been set up correctly by the caller
local function get_lua_dir()
  -- Check if lua_dir was stored in global by config loader
  if _G.WEZMACS_LUA_DIR then
    return _G.WEZMACS_LUA_DIR
  end
  
  -- Try package.searchpath on wezmacs.module (should work if already loaded)
  local test_path = package.searchpath("wezmacs.module", package.path)
  if test_path then
    local lua_dir = test_path:match("^(.+)/module%.lua$")
    if lua_dir then
      return lua_dir
    end
  end
  
  -- Try package.searchpath on wezmacs.init
  test_path = package.searchpath("wezmacs.init", package.path)
  if test_path then
    local lua_dir = test_path:match("^(.+)/init%.lua$")
    if lua_dir then
      return lua_dir
    end
  end
  
  -- Final fallback: assume we're in XDG_DATA_HOME/wezmacs/lua/
  local xdg_data = os.getenv("XDG_DATA_HOME")
  if xdg_data then
    return xdg_data .. "/wezmacs/lua"
  end
  
  local home = os.getenv("HOME") or ""
  return home .. "/.local/share/wezmacs/lua"
end

-- Get modules directory (lua/wezmacs/modules/)
local function get_modules_dir()
  local lua_dir = get_lua_dir()
  return lua_dir .. "/wezmacs/modules"
end

-- Discover all built-in modules from lua/wezmacs/modules/
---@param log function Logging function
---@return table Array of module names
local function discover_builtin_modules(log)
  local modules_dir = get_modules_dir()
  
  log("info", "Scanning for modules in: " .. modules_dir)
  
  local modules = {}
  
  -- Scan modules directory for .lua files
  local handle = io.popen("ls -1 '" .. modules_dir .. "' 2>/dev/null | grep '\\.lua$'")
  if handle then
    for file in handle:lines() do
      local mod_name = file:match("^(.+)%.lua$")
      if mod_name and mod_name ~= "titles" then  -- Skip helper files
        table.insert(modules, mod_name)
        log("info", "Found module: " .. mod_name)
      end
    end
    handle:close()
  else
    log("warn", "Could not scan modules directory: " .. modules_dir)
  end
  
  log("info", "Discovered " .. #modules .. " built-in modules")
  return modules
end

-- Discover user custom modules from wezterm.config_dir/modules/
---@param log function Logging function
---@return table Array of module names
local function discover_user_modules(log)
  local wezterm = require("wezterm")
  local wezterm_config_dir = wezterm.config_dir
  if not wezterm_config_dir then
    -- Fallback to ~/.config/wezterm if config_dir not available
    local home = os.getenv("HOME") or ""
    wezterm_config_dir = home .. "/.config/wezterm"
  end
  
  local user_modules_dir = wezterm_config_dir .. "/modules"
  local modules = {}
  
  -- Scan user modules directory for .lua files
  local handle = io.popen("ls -1 '" .. user_modules_dir .. "' 2>/dev/null | grep '\\.lua$'")
  if handle then
    for file in handle:lines() do
      local mod_name = file:match("^(.+)%.lua$")
      if mod_name then
        table.insert(modules, mod_name)
      end
    end
    handle:close()
  end
  
  return modules
end

-- Load a single module (supports both module.lua and module/init.lua)
---@param mod_name string Module name
---@param is_user_module boolean Whether this is a user custom module
---@param log function Logging function
---@return table|nil Loaded module spec or nil if failed
function M.load_module(mod_name, is_user_module, log)
  local ok, spec
  
  if is_user_module then
    -- Load user custom module from wezterm.config_dir/modules/
    local wezterm = require("wezterm")
    local wezterm_config_dir = wezterm.config_dir
    if not wezterm_config_dir then
      -- Fallback to ~/.config/wezterm if config_dir not available
      local home = os.getenv("HOME") or ""
      wezterm_config_dir = home .. "/.config/wezterm"
    end
    
    -- Try to load directly from file
    local module_path = wezterm_config_dir .. "/modules/" .. mod_name .. ".lua"
    local file = io.open(module_path, "r")
    if file then
      file:close()
      -- Setup package.path to allow requires in user module
      local old_path = package.path
      package.path = wezterm_config_dir .. "/modules/?.lua;" .. package.path
      
      -- Load using loadfile
      local chunk, err = loadfile(module_path)
      if chunk then
        ok, spec = pcall(chunk)
      else
        ok = false
        spec = err
      end
      
      package.path = old_path
    else
      ok = false
      spec = "File not found: " .. module_path
    end
  else
    -- Load built-in module from WEZMACS_DIR/modules/
    local require_path = "wezmacs.modules." .. mod_name
    ok, spec = pcall(require, require_path)

    -- If not found, try module/init.lua (nested structure)
    if not ok then
      require_path = "wezmacs.modules." .. mod_name .. ".init"
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
---@param user_spec table|nil User module spec overrides (from config.lua)
---@return table Array of enabled module specs
---@return table Map of all module specs
function M.load_all(log, user_spec)
  log("info", "Discovering modules...")
  
  -- Discover all built-in modules from lua/modules/
  local builtin_module_names = discover_builtin_modules(log)
  log("info", "Found " .. #builtin_module_names .. " built-in module names to load")
  
  -- Load all built-in module specs
  local specs = {}
  for _, mod_name in ipairs(builtin_module_names) do
    local spec = M.load_module(mod_name, false, log)
    if spec then
      specs[mod_name] = spec
    end
  end

  -- Discover and load user custom modules from ~/.config/wezterm/modules/
  local user_module_names = discover_user_modules(log)
  for _, mod_name in ipairs(user_module_names) do
    -- Skip if already loaded (user module overrides built-in)
    if not specs[mod_name] then
      local spec = M.load_module(mod_name, true, log)
      if spec then
        specs[mod_name] = spec
      end
    else
      log("warn", "User module '" .. mod_name .. "' conflicts with built-in module, skipping")
    end
  end

  -- Merge user spec overrides (passed from wezterm.lua)
  if user_spec and type(user_spec) == "table" then
    merge_user_config(specs, user_spec, log)
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
