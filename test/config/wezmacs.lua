--[[
  WezMacs Test Configuration Loader

  This file loads the WezMacs framework from the local lua/ directory
  for testing purposes.
]]

local wezterm = require("wezterm")

-- Clear WezMacs module cache to force reload during development
-- This ensures changes to lua/wezmacs/* files are picked up
for k in pairs(package.loaded) do
  if k:match("^wezmacs") then
    package.loaded[k] = nil
  end
end

-- Get the local lua directory from repo root
local function get_local_lua_dir()
  -- Get the directory of the wezterm.lua file (test/)
  local config_dir = wezterm.config_dir
  if config_dir then
    -- config_dir is test/, so lua/ is at the parent directory
    local repo_root = config_dir:match("^(.+)/[^/]+$")
    if repo_root then
      local lua_dir = repo_root .. "/lua"
      wezterm.log_info("[WezMacs] Using lua directory: " .. lua_dir)
      return lua_dir
    end
  end
  
  -- Fallback: try to determine from current working directory
  local cwd = io.popen("pwd"):read("*l")
  local lua_dir = cwd .. "/lua"
  wezterm.log_info("[WezMacs] Using lua directory (fallback): " .. lua_dir)
  return lua_dir
end

-- Setup package.path to find wezmacs from local lua directory
local function setup_local_wezmacs_path(lua_dir)
  -- Store lua_dir in a global so module.lua can find it
  _G.WEZMACS_LUA_DIR = lua_dir
  
  -- Escape special characters for pattern matching
  local escaped_path = lua_dir:gsub("%-", "%%-")
  -- Add lua directory to package.path so require("wezmacs") loads lua/wezmacs/init.lua
  -- and require("wezmacs.action") loads lua/wezmacs/action.lua
  package.path = escaped_path .. "/?.lua;" .. escaped_path .. "/?/init.lua;" .. package.path
end

-- Load user spec from WEZMACS_CONFIG_DIR or test directory
local function load_user_spec()
  local wezmacs_config_dir = os.getenv("WEZMACS_CONFIG_DIR")
  if not wezmacs_config_dir then
    -- Default to test directory for testing
    local config_dir = wezterm.config_dir
    if config_dir then
      wezmacs_config_dir = config_dir
    else
      local home = os.getenv("HOME") or ""
      wezmacs_config_dir = home .. "/.config/wezmacs"
    end
  end
  
  local config_path = wezmacs_config_dir .. "/config.lua"
  local file = io.open(config_path, "r")
  if not file then
    return nil  -- No user config, use defaults
  end
  file:close()

  -- Load config file
  local chunk, err = loadfile(config_path)
  if not chunk then
    wezterm.log_error("[WezMacs] Failed to load user config: " .. tostring(err))
    return nil
  end

  -- Setup package.path for any requires in user config
  local old_path = package.path
  package.path = wezmacs_config_dir .. "/?.lua;" .. package.path

  -- Execute chunk
  local success, user_spec = pcall(chunk)
  package.path = old_path

  if success and user_spec then
    return user_spec
  end

  return nil
end

-- Main initialization
local lua_dir = get_local_lua_dir()

-- Verify lua directory exists
local init_file = lua_dir .. "/wezmacs/init.lua"
local file = io.open(init_file, "r")
if not file then
  wezterm.log_error("[WezMacs] Local lua directory not found: " .. lua_dir)
  return wezterm.config_builder()
end
file:close()

-- Setup package.path
setup_local_wezmacs_path(lua_dir)

-- Load wezmacs framework
local wezmacs = require("wezmacs")

-- Create wezterm config
local config = wezterm.config_builder()

-- Load user spec
local user_spec = load_user_spec()

-- Initialize framework with user spec
wezmacs.setup(config, user_spec)

return config
