--[[
  WezMacs Module Loading
  
  Handles loading modules from directories.
]]

local wezterm = require("wezterm")

-- Load modules.lua from wezmacs config directory
local function list(wezmacs_dir)
	return function()
		local modules_path = wezmacs_dir .. "/modules.lua"
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
end

-- Parse module entry (string or table)
local function parse_entry(entry)
	if type(entry) == "string" then
		return { name = entry, opts = {}, keys = {} }, nil
	elseif type(entry) == "table" then
		return {
			name = entry[1],
			opts = entry.opts or {},
			keys = entry.keys or {},
		}, nil
	else
		return nil, "invalid module entry: " .. tostring(entry)
	end
end

local function deep_merge(a, b)
	if not a and not b then
		return {}
	elseif not a then
		return b
	elseif not b then
		return a
	end

	local out = {}
	for k, v in pairs(a) do
		out[k] = v
	end

	for k, v in pairs(b) do
		if type(v) == "table" and type(out[k]) == "table" then
			out[k] = deep_merge(out[k], v)
		else
			out[k] = v
		end
	end

	return out
end

-- Get the module options
local function get_opts(mod, mod_config)
	local opts = mod.opts or {}
	if type(opts) == "function" then
		opts = opts()
	end

	local user_opts = mod_config.opts
	if type(user_opts) == "function" then
		user_opts = user_opts()
	end

	return deep_merge(opts, user_opts)
end

-- Get the module keybindings
local function get_keys(mod, mod_config, opts)
	local keys = mod.keys or {}
	if type(keys) == "function" then
		keys = keys(opts)
	end

	local user_keys = mod_config.keys
	if type(user_keys) == "function" then
		user_keys = user_keys(opts)
	end

	return deep_merge(keys, user_keys)
end

-- Get the module deps
local function get_deps(mod, mod_config, opts)
	local deps = mod.deps or {}
	if type(deps) == "function" then
		deps = deps(opts)
	end

	local user_deps = mod_config.deps
	if type(user_deps) == "function" then
		user_deps = user_deps(opts)
	end

	return deep_merge(deps, user_deps)
end

-- Return the setup function
local function get_setup(mod, mod_config)
	if mod.setup and mod_config.setup then
		return function(config, opts)
			mod.setup(config, opts)
			config.setup(config, opts)
		end
	elseif mod.setup then
		return mod.setup
	elseif mod_config.setup then
		return mod_config.setup
	else
		return function(_, _) end
	end
end

-- Load a module from wezmacs_framework_dir/modules or wezterm_config_dir/modules
-- Modules are in directory structure: module-name/init.lua
local function load(entry)
	local mod_config, err = parse_entry(entry)
	if err then
		return nil, err
	elseif not mod_config then
		return nil, "unable to parse entry"
	end

	local mod = require("wezmacs.modules." .. mod_config.name)
	if not mod then
		return nil, mod_config.name .. ": not found"
	end
	wezterm.log_info("[WezMacs] Loaded Module: " .. mod.name)

	local opts = get_opts(mod, mod_config)
	return {
		name = mod_config.name,
		opts = opts,
		deps = get_deps(mod, mod_config, opts),
		keys = get_keys(mod, mod_config, opts),
		setup = get_setup(mod, mod_config),
	},
		nil
end

return function(wezmacs_dir)
	return {
		list = list(wezmacs_dir),
		load = load,
	}
end
