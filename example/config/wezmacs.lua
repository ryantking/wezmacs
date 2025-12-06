--[[
  WezMacs Configuration Loader

  This file loads the WezMacs framework from XDG_DATA_HOME/wezmacs/lua/
  (defaults to ~/.local/share/wezmacs/lua/) and initializes it with user configuration.

  User Configuration:
  - ~/.config/wezmacs/config.lua: Module overrides
  - ~/.config/wezmacs/setup.lua: Custom setup function
  - ~/.config/wezmacs/keys.lua: Custom keybindings
  - ~/.config/wezterm/modules/: User custom modules
]]

local wezterm = require("wezterm")

-- Optional: Clear WezMacs module cache to force reload
-- Uncomment the following lines during development to pick up changes:
-- for k in pairs(package.loaded) do
--   if k:match("^wezmacs") then
--     package.loaded[k] = nil
--   end
-- end

-- Determine wezmacs installation directory
local function get_wezmacs_dir()
  local xdg_data = os.getenv("XDG_DATA_HOME")
  if xdg_data then
    return xdg_data .. "/wezmacs"
  end

  local home = os.getenv("HOME") or ""
  return home .. "/.local/share/wezmacs"
end

-- Git clone wezmacs if directory doesn't exist
local function ensure_wezmacs_installed(wezmacs_dir)
  local lua_dir = wezmacs_dir .. "/lua"
  local init_file = lua_dir .. "/wezmacs/init.lua"
  local file = io.open(init_file, "r")
  if file then
    file:close()
    return true  -- Already installed
  end

  -- Directory doesn't exist, clone it
  wezterm.log_info("[WezMacs] Installing WezMacs to: " .. wezmacs_dir)
  
  -- Create parent directory if needed
  local parent_dir = wezmacs_dir:match("^(.+)/[^/]+$")
  if parent_dir then
    os.execute("mkdir -p '" .. parent_dir .. "'")
  end

  -- Git clone wezmacs repository
  local repo_url = "https://github.com/ryantking/wezmacs.git"
  local clone_cmd = "git clone " .. repo_url .. " " .. wezmacs_dir .. " 2>&1"
  
  wezterm.log_info("[WezMacs] Cloning repository...")
  local handle = io.popen(clone_cmd)
  if handle then
    local output = handle:read("*all")
    handle:close()
    
    -- Check if clone succeeded
    file = io.open(init_file, "r")
    if file then
      file:close()
      wezterm.log_info("[WezMacs] Installation complete")
      return true
    else
      wezterm.log_error("[WezMacs] Installation failed. Output: " .. output)
      return false
    end
  else
    wezterm.log_error("[WezMacs] Failed to execute git clone")
    return false
  end
end

-- Setup package.path to find wezmacs
local function setup_wezmacs_path(wezmacs_dir)
  local lua_dir = wezmacs_dir .. "/lua"
  -- Store lua_dir in a global so module.lua can find it
  _G.WEZMACS_LUA_DIR = lua_dir
  
  -- Escape special characters for pattern matching
  local escaped_path = lua_dir:gsub("%-", "%%-")
  -- Add lua directory to package.path so require("wezmacs") loads lua/wezmacs/init.lua
  -- and require("wezmacs.action") loads lua/wezmacs/action.lua
  package.path = escaped_path .. "/?.lua;" .. escaped_path .. "/?/init.lua;" .. package.path
end

-- Load user spec from config.lua
local function load_user_spec()
  local wezmacs_config_dir = os.getenv("WEZMACS_CONFIG_DIR")
  if not wezmacs_config_dir then
    local home = os.getenv("HOME") or ""
    wezmacs_config_dir = home .. "/.config/wezmacs"
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
-- Guard against double initialization (WezTerm can load config multiple times)
if _G._WEZMACS_INITIALIZED then
  -- Already initialized, return existing config
  return wezterm.config_builder()
end

local wezmacs_dir = get_wezmacs_dir()

-- Ensure wezmacs is installed
if not ensure_wezmacs_installed(wezmacs_dir) then
  wezterm.log_error("[WezMacs] Failed to install WezMacs framework")
  return wezterm.config_builder()
end

-- Setup package.path
setup_wezmacs_path(wezmacs_dir)

-- Load wezmacs framework
local wezmacs = require("wezmacs")

-- Create wezterm config
local config = wezterm.config_builder()

-- Load user spec
local user_spec = load_user_spec()

-- Initialize framework with user spec
wezmacs.setup(config, user_spec)

-- Mark as initialized
_G._WEZMACS_INITIALIZED = true

return config
