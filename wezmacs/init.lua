--[[
  WezMacs Framework API

  Main entry point for modules to access WezMacs functionality.

  Usage:
    local wezmacs = require('wezmacs')
    wezmacs.config.font_size      -- Access global config
    wezmacs.keys.map(...)         -- Map keybindings
    wezmacs.action.SmartSplit()   -- Use actions
]]

local M = {}

-- Configuration will be set during initialization by wezterm.lua
-- Modules access via: wezmacs.config.some_setting
M.config = {}

-- Discover wezmacs user config directory (where modules.lua and config.lua are)
-- Priority: WEZMACSDIR env var > XDG_CONFIG_HOME/wezmacs > ~/.config/wezmacs
local function get_wezmacs_config_dir()
  local wezmacs_dir = os.getenv("WEZMACSDIR")
  if wezmacs_dir then
    return wezmacs_dir
  end

  local xdg_config = os.getenv("XDG_CONFIG_HOME")
  if xdg_config then
    return xdg_config .. "/wezmacs"
  end

  local home = os.getenv("HOME") or ""
  return home .. "/.config/wezmacs"
end

M.config_dir = get_wezmacs_config_dir()

-- Keybindings API (lazy load)
-- Usage: wezmacs.keys.map(config, key_map, module_name)
M.keys = setmetatable({}, {
  __index = function(t, k)
    local keys_module = require("wezmacs.keys")
    for key, value in pairs(keys_module) do
      rawset(t, key, value)
    end
    return t[k]
  end,
})

-- Action API
-- Usage: wezmacs.action.SmartSplit("lazygit")
M.action = require("wezmacs.action")

-- Backward compatibility: lib.keybindings points to keys
M.lib = {
  keybindings = M.keys,
}

return M
