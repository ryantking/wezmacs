--[[
  WezMacs User Configuration Entry Point
  
  This file should be copied to ~/.config/wezterm/wezterm.lua
  It loads the WezMacs framework and runs setup.
]]

local wezterm = require("wezterm")

-- Add ~/.config/wezterm/wezmacs to package.path so require("wezmacs.*") works
local wezterm_config_dir = wezterm.config_dir or (os.getenv("HOME") or "") .. "/.config/wezterm"
local wezmacs_dir = wezterm_config_dir .. "/wezmacs"
package.path = wezmacs_dir .. "/?.lua;" .. wezmacs_dir .. "/?/init.lua;" .. package.path

return require("wezmacs.setup").setup()
