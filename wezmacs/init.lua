--[[
  WezMacs Framework Bootstrap

  Main entry point for the WezMacs modular wezterm configuration framework.
  Orchestrates module loading, configuration merging, and initialization.
]]

local wezterm = require("wezterm")
local module_loader = require("wezmacs.module")

local M = {}

-- Load user files from ~/.config/wezmacs/
---@param log function Logging function
---@return function|nil User setup function
---@return table|function|nil User keys (table or function)
local function load_user_files(log)
  local home = os.getenv("HOME") or ""
  local wezmacs_config_dir = home .. "/.config/wezmacs"
  
  -- Load user setup.lua
  local user_setup = nil
  local setup_path = wezmacs_config_dir .. "/setup.lua"
  local ok, result = pcall(function()
    local file = io.open(setup_path, "r")
    if not file then
      return nil
    end
    file:close()
    
    local chunk, err = loadfile(setup_path)
    if not chunk then
      log("error", "Failed to load user setup: " .. tostring(err))
      return nil
    end
    
    local old_path = package.path
    package.path = wezmacs_config_dir .. "/?.lua;" .. package.path
    
    local success, setup_module = pcall(chunk)
    package.path = old_path
    
    if success and setup_module and type(setup_module.setup) == "function" then
      return setup_module.setup
    end
    return nil
  end)
  if ok and result then
    user_setup = result
    log("info", "Loaded user setup from ~/.config/wezmacs/setup.lua")
  else
    log("info", "No user setup found at ~/.config/wezmacs/setup.lua (this is optional)")
  end

  -- Load user keys.lua
  local user_keys = nil
  local keys_path = wezmacs_config_dir .. "/keys.lua"
  ok, result = pcall(function()
    local file = io.open(keys_path, "r")
    if not file then
      return nil
    end
    file:close()
    
    local chunk, err = loadfile(keys_path)
    if not chunk then
      log("error", "Failed to load user keys: " .. tostring(err))
      return nil
    end
    
    local old_path = package.path
    package.path = wezmacs_config_dir .. "/?.lua;" .. package.path
    
    local success, keys_module = pcall(chunk)
    package.path = old_path
    
    if success and keys_module then
      if type(keys_module) == "function" then
        return keys_module
      elseif type(keys_module.keys) == "function" then
        return keys_module.keys
      elseif type(keys_module.keys) == "table" then
        return function() return keys_module.keys end
      elseif type(keys_module) == "table" then
        return function() return keys_module end
      end
    end
    return nil
  end)
  if ok and result then
    user_keys = result
    log("info", "Loaded user keys from ~/.config/wezmacs/keys.lua")
  else
    log("info", "No user keys found at ~/.config/wezmacs/keys.lua (this is optional)")
  end

  return user_setup, user_keys
end

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

  log("info", "Loading WezMacs framework")

  -- Load all modules (discover built-in, merge user config)
  local modules, all_specs = module_loader.load_all(log)

  -- Create global wezmacs API table
  _G.wezmacs = {
    -- Get module spec
    get_spec = function(module_name)
      return all_specs[module_name]
    end,

    -- Check if module is loaded
    has_module = function(module_name)
      local registry = require("wezmacs.lib.registry")
      return registry.is_loaded(module_name)
    end,

    -- Library access
    lib = {
      keybindings = require("wezmacs.lib.keybindings"),
      theme = require("wezmacs.lib.theme"),
      config = require("wezmacs.lib.config"),
    },
    -- Action API (top-level, not in lib)
    action = require("wezmacs.action"),
  }

  local keybindings = require("wezmacs.lib.keybindings")

  -- Apply CORE module first if present (core settings must be applied before others)
  for i, spec in ipairs(modules) do
    if spec.name == "core" then
      log("info", "Applying CORE module first")
      if spec.setup then
        spec.setup(config, spec)
      end
      table.remove(modules, i)
      break
    end
  end

  -- Apply remaining modules
  for _, spec in ipairs(modules) do
    local mod_name = spec.name or "unknown"
    log("info", "Applying module: " .. mod_name)

    -- Call setup with config and full spec
    if spec.setup then
      spec.setup(config, spec)
    end
  end

  -- Load and apply user setup function
  local user_setup, user_keys = load_user_files(log)
  if user_setup then
    log("info", "Applying user setup function")
    -- Create combined spec for user setup
    local combined_spec = {}
    for mod_name, spec in pairs(all_specs) do
      combined_spec[mod_name] = spec
    end
    user_setup(config, combined_spec)
  end

  -- Apply all module keys
  for _, spec in ipairs(modules) do
    if spec.keys then
      local opts = spec.opts()
      keybindings.apply_keys(config, spec, opts)
    end
  end

  -- Apply user keys
  if user_keys then
    log("info", "Applying user keybindings")
    local user_key_map
    if type(user_keys) == "function" then
      user_key_map = user_keys()
    elseif type(user_keys) == "table" then
      user_key_map = user_keys
    end
    
    if user_key_map and type(user_key_map) == "table" then
      keybindings.apply_keys(config, {
        name = "user",
        keys = function() return user_key_map end,
      }, {})
    end
  end

  log("info", "WezMacs framework initialized successfully (" .. #modules .. " modules loaded)")
end

return M
