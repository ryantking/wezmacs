--[[
  WezMacs Module Loading
  
  Handles loading modules from directories.
]]

local wezterm = require("wezterm")

local M = {}

-- Load modules.lua from wezmacs config directory
function M.list(wezmacs_config_dir)
	local modules_path = wezmacs_config_dir .. "/modules.lua"
	local file = io.open(modules_path, "r")
	if not file then
		wezterm.log_error("[WezMacs] modules.lua not found at " .. modules_path)
		return {}
	end
	file:close()

	local chunk, err = loadfile(modules_path)
	if not chunk then
		wezterm.log_error("[WezMacs] Failed to load modules.lua: " .. tostring(err))
		return {}
	end

	local success, modules = pcall(chunk)
	if not success then
		wezterm.log_error("[WezMacs] Error executing modules.lua: " .. tostring(modules))
		return {}
	end

	if type(modules) ~= "table" then
		wezterm.log_error("[WezMacs] modules.lua must return a table")
		return {}
	end

	return modules
end

-- Load a module from wezmacs_framework_dir/modules or wezterm_config_dir/modules
-- Modules are in directory structure: module-name/init.lua
function M.load(module_name, wezmacs_framework_dir, wezterm_config_dir)
	-- Try wezmacs_framework_dir/modules/module-name/init.lua first
	local wezmacs_module_path = wezmacs_framework_dir .. "/modules/" .. module_name .. "/init.lua"
	local file = io.open(wezmacs_module_path, "r")
	if file then
		file:close()
		-- Set up package.path to allow local requires within the module
		local module_dir = wezmacs_framework_dir .. "/modules/" .. module_name
		local old_path = package.path
		package.path = module_dir .. "/?.lua;" .. package.path

		local chunk, err = loadfile(wezmacs_module_path)
		if chunk then
			local success, mod = pcall(chunk)
			package.path = old_path -- Restore package.path
			if success and mod then
				return mod
			end
		else
			package.path = old_path -- Restore package.path on error
		end
	end

	-- Try wezterm_config_dir/modules/module-name/init.lua
	if wezterm_config_dir then
		local user_module_path = wezterm_config_dir .. "/modules/" .. module_name .. "/init.lua"
		local file = io.open(user_module_path, "r")
		if file then
			file:close()
			-- Set up package.path to allow local requires within the module
			local module_dir = wezterm_config_dir .. "/modules/" .. module_name
			local old_path = package.path
			package.path = module_dir .. "/?.lua;" .. package.path

			local chunk, err = loadfile(user_module_path)
			if chunk then
				local success, mod = pcall(chunk)
				package.path = old_path -- Restore package.path
				if success and mod then
					return mod
				end
			else
				package.path = old_path -- Restore package.path on error
			end
		end
	end

	return nil
end

return M
