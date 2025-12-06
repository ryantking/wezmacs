--[[
  WezMacs Example Configuration

  This is an example wezterm.lua that loads WezMacs from the user's
  XDG_DATA_HOME/wezmacs/lua/ directory (defaults to ~/.local/share/wezmacs/lua/).
]]

local wezterm = require("wezterm")

-- Setup package.path to find config.wezmacs
-- wezterm.config_dir points to the directory containing this file (~/.config/wezterm/)
local config_dir = wezterm.config_dir
if config_dir then
  -- Add ~/.config/wezterm/config/ to package.path so require("config.wezmacs") works
  package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path
end

return require("config.wezmacs")
