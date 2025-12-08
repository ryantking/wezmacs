--[[
  WezMacs Framework Entrypoint
]]

local wezterm = require("wezterm")

-- Load the WezMacs framework
-- WezTerm only adds ~/.config/wezterm by default, regardless of WEZTERM_CONFIG_FILE
package.path = wezterm.config_dir .. "/?.lua;" .. wezterm.config_dir .. "/?/init.lua;" .. package.path
local wezmacs = require("wezmacs")
wezterm.log_info("[WezMacs] Loaded Framework: " .. wezterm.config_dir)
wezterm.log_info("[WezMacs] Config Directory: " .. wezmacs.config_dir)

-- Load and apply each module
local config = wezterm.config_builder()
local modules_list = wezmacs.module.list()
for _, module_entry in ipairs(modules_list) do
	local mod, err = wezmacs.module.load(module_entry)
	if err then
		wezterm.log_error("[WezMacs] Module Error: " .. tostring(err))
	elseif not mod then
		wezterm.log_error("[WezMacs] Unable to load module: " .. tostring(module_entry))
	else
		mod.setup(config, mod.opts)
		if mod.keys and type(mod.keys) == "table" then
			wezmacs.keys.map(config, mod.keys, mod.name or "unknown")
		end
	end
end

wezterm.log_info("[WezMacs] Configuration loaded successfully")

return config
