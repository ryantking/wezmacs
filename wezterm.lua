--[[
  WezMacs Development Configuration
  
  This file loads WezMacs from the local wezmacs/ directory for development/testing.
  Used with: wezterm --config-file wezterm.lua start
]]

local wezterm = require("wezterm")

-- Use wezterm.config_dir directly (set correctly via WEZTERM_CONFIG_FILE)
local config_dir = wezterm.config_dir

-- Framework directory is at wezterm.config_dir/wezmacs
local wezmacs_framework_dir = config_dir .. "/wezmacs"

-- Add wezmacs framework to package.path FIRST before requiring anything
-- Put local directory FIRST to ensure we load local version, not global cached one
-- This allows us to require wezmacs.lib.*, wezmacs.action, wezmacs.module, etc.
local old_path = package.path
package.path = wezmacs_framework_dir
  .. "/?.lua;"
  .. wezmacs_framework_dir
  .. "/?/init.lua;"
  .. old_path

-- Clear any cached wezmacs modules to ensure we load fresh versions
for k, _ in pairs(package.loaded) do
  if k:match("^wezmacs") then
    package.loaded[k] = nil
  end
end

-- Load wezmacs API directly from file to avoid cache issues
local init_path = wezmacs_framework_dir .. "/init.lua"
local init_chunk, init_err = loadfile(init_path)
if not init_chunk then
  wezterm.log_error("[WezMacs] Failed to load init.lua: " .. tostring(init_err))
  return wezterm.config_builder()
end

local init_success, wezmacs = pcall(init_chunk)
if not init_success or not wezmacs then
  wezterm.log_error("[WezMacs] Failed to execute init.lua: " .. tostring(wezmacs))
  return wezterm.config_builder()
end

-- Store wezmacs in package.loaded so modules that require("wezmacs") get the same instance
package.loaded["wezmacs"] = wezmacs

-- Update config_dir if WEZMACSDIR is set (for testing)
local wezmacs_dir_env = os.getenv("WEZMACSDIR")
if wezmacs_dir_env then
  wezmacs.config_dir = wezmacs_dir_env
end

-- IMPORTANT: Load config FIRST before any modules are loaded
-- This ensures config is available when modules require('wezmacs')
local config_module = require("wezmacs.config")
local config_path = wezmacs.config_dir .. "/config.lua"
local wezmacs_config = config_module.load(config_path)

-- Store config in global wezmacs API BEFORE loading modules
-- This prevents modules from caching an empty config
wezmacs.config = wezmacs_config

wezterm.log_info("[WezMacs] Framework directory: " .. wezmacs_framework_dir)
wezterm.log_info("[WezMacs] Config directory: " .. wezmacs.config_dir)

-- Load module loading functions now that package.path is set
-- Load directly from local file to avoid any cache or path resolution issues
local module_path = wezmacs_framework_dir .. "/module.lua"
local chunk, err = loadfile(module_path)
if not chunk then
  wezterm.log_error(
    "[WezMacs] Failed to load module.lua from " .. module_path .. ": " .. tostring(err)
  )
  return wezterm.config_builder()
end

-- Execute the chunk (module.lua returns M table)
local success, module_loader = pcall(chunk)
if not success then
  wezterm.log_error("[WezMacs] Error executing module.lua: " .. tostring(module_loader))
  return wezterm.config_builder()
end

if not module_loader or not module_loader.list then
  wezterm.log_error("[WezMacs] Module loader missing list function")
  if module_loader then
    local funcs = {}
    for k, v in pairs(module_loader) do
      if type(v) == "function" then
        table.insert(funcs, k)
      end
    end
    wezterm.log_error("[WezMacs] Module loader has: " .. table.concat(funcs, ", "))
  end
  return wezterm.config_builder()
end

-- Load modules list AFTER config is set
local modules_list = module_loader.list(wezmacs.config_dir)
wezterm.log_info("[WezMacs] Loaded " .. #modules_list .. " modules from modules.lua")

-- Create wezterm config
local config = wezterm.config_builder()

-- Load and apply each module
for _, module_entry in ipairs(modules_list) do
  local module_name
  local user_opts = {}
  local user_keys = nil

  -- Parse module entry (string or table)
  if type(module_entry) == "string" then
    module_name = module_entry
  elseif type(module_entry) == "table" then
    module_name = module_entry[1]
    user_opts = module_entry.opts or {}
    user_keys = module_entry.keys
  else
    wezterm.log_error("[WezMacs] Invalid module entry: " .. tostring(module_entry))
    goto continue
  end

  -- Load module
  local mod = module_loader.load(module_name, wezmacs_framework_dir, config_dir)
  if not mod then
    wezterm.log_error("[WezMacs] Module not found: " .. module_name)
    goto continue
  end

  -- Get default opts and merge with user opts
  local default_opts = {}
  if type(mod.opts) == "function" then
    default_opts = mod.opts()
  elseif type(mod.opts) == "table" then
    default_opts = mod.opts
  end

  -- Deep merge user opts into default opts
  local opts = default_opts
  for k, v in pairs(user_opts) do
    if type(v) == "table" and type(opts[k]) == "table" then
      -- Simple merge for nested tables (could be improved with deep merge)
      for k2, v2 in pairs(v) do
        opts[k][k2] = v2
      end
    else
      opts[k] = v
    end
  end

  -- Run module setup (pass config and opts)
  if type(mod.setup) == "function" then
    mod.setup(config, opts)
  end

  -- Apply keybindings using wezmacs.keys.map with rendered table structure
  local keys = user_keys
  if not keys then
    if type(mod.keys) == "function" then
      keys = mod.keys(opts)
    elseif type(mod.keys) == "table" then
      keys = mod.keys
    end
  end

  if keys and type(keys) == "table" then
    wezmacs.keys.map(config, keys, mod.name or "unknown")
  end

  ::continue::
end

wezterm.log_info("[WezMacs] Configuration loaded successfully")

return config
