--[[
  WezMacs Test Configuration

  This is the test wezterm.lua that loads WezMacs from the local
  lua/ directory for testing.
]]

local wezterm = require("wezterm")

-- Setup package.path to find config.wezmacs
-- wezterm.config_dir points to the directory containing this file (test/)
local config_dir = wezterm.config_dir
if config_dir then
  -- Add test/config/ to package.path so require("config.wezmacs") works
  package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path
end

return require("config.wezmacs")
