--[[
  WezMacs Configuration Management
  
  Provides default global settings and a function to load user configuration.
]]

local wezterm = require("wezterm")

local M = {}

-- Default global configuration
M.defaults = {
	color_scheme = "Rose Pine", -- Default theme
	term_mod = "CTRL|SHIFT", -- Default modifier for bindings
	gui_mod = "SUPER", -- Modifier for gui commands
	ctrl_mod = "CTRL", -- Modifier for control commands
	alt_mod = "ALT", -- Modifier for alt commands
	shell = os.getenv("SHELL") or "/bin/bash", -- User's shell
	platform = wezterm.target_triple:match("darwin") ~= nil and "darwin" or "linux",
	-- Add more defaults as needed
}

local function clone(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in pairs(value) do
		copy[key] = clone(child)
	end
	return copy
end

-- Load an optional user file. Top-level settings replace defaults in full,
-- including arrays; this is intentionally not the module option deep merge.
-- Existing malformed/unreadable files raise, rather than using wrong settings.
function M.load(user_config_path)
	local config = {}

	-- Start with defaults
	for k, v in pairs(M.defaults) do
		config[k] = clone(v)
	end

	-- Try to load user config file
	if user_config_path then
		local file, open_err, code = io.open(user_config_path, "r")
		-- ENOENT is 2 on the platforms supported by WezTerm.
		if not file and code ~= 2 then
			error("[WezMacs] " .. user_config_path .. ": open failed: " .. tostring(open_err), 0)
		end
		if file then
			file:close()

			local chunk, err = loadfile(user_config_path)
			if not chunk then
				error("[WezMacs] " .. user_config_path .. ": load failed: " .. tostring(err), 0)
			end
			local success, user_config = pcall(chunk)
			if not success then
				error("[WezMacs] " .. user_config_path .. ": execute failed: " .. tostring(user_config), 0)
			end
			if type(user_config) ~= "table" then
				error("[WezMacs] " .. user_config_path .. ": must return a table", 0)
			end
			for k, v in pairs(user_config) do
				config[k] = clone(v)
			end
		end
	end

	return config
end

return M
