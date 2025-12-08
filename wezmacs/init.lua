--[[
  WezMacs Framework API

  Main entry point for modules to access WezMacs functionality.

  Usage:
    local wezmacs = require('wezmacs')
    wezmacs.config.color_scheme    -- Access global config
    wezmacs.keys.map(...)         -- Map keybindings
    wezmacs.action.SmartSplit()   -- Use actions
]]

local M = {}

-- Action API
-- Usage: wezmacs.action.SmartSplit("lazygit")
M.action = require("wezmacs.action")

-- Discover wezmacs user config directory (where modules.lua and config.lua are)
-- Priority: WEZMACSDIR env var > XDG_CONFIG_HOME/wezmacs > ~/.config/wezmacs
local function get_wezmacs_dir()
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

M.config_dir = get_wezmacs_dir()

local function load_config()
	local config_path = M.config_dir .. "/config.lua"
	return require("wezmacs.config").load(config_path)
end

-- Global configuration
M.config = load_config()

-- Module API
-- Usage: wezmacs.module.list()
M.module = require("wezmacs.module")(M.config_dir)

-- Color scheme (computed from config.color_scheme)
-- Access via: wezmacs.color_scheme (returns the theme object or nil)
-- This is computed lazily when accessed
local color_scheme_cache = nil
function M.color_scheme()
	if color_scheme_cache == nil and M.config and M.config.color_scheme then
		local wezterm = require("wezterm")
		local schemes = wezterm.get_builtin_color_schemes()
		color_scheme_cache = schemes[M.config.color_scheme]
	end
	return color_scheme_cache
end

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

return M
