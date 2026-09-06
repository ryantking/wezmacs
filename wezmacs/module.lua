--[[
  WezMacs Module Loading
  
  Handles loading modules from directories.
]]

local wezterm = require("wezterm")

-- Load modules.lua from wezmacs config directory
local function list(wezmacs_dir)
	return function()
		local modules_path = wezmacs_dir .. "/modules.lua"
		local file, open_err = io.open(modules_path, "r")
		if not file then
			error("[WezMacs] " .. modules_path .. ": open failed (modules.lua is required): " .. tostring(open_err), 0)
		end
		file:close()

		local chunk, err = loadfile(modules_path)
		if not chunk then
			error("[WezMacs] " .. modules_path .. ": load failed: " .. tostring(err), 0)
		end

		local success, modules = pcall(chunk)
		if not success then
			error("[WezMacs] " .. modules_path .. ": execute failed: " .. tostring(modules), 0)
		end

		if type(modules) ~= "table" then
			error("[WezMacs] " .. modules_path .. ": must return a table", 0)
		end

		local count, maximum = 0, 0
		for key in pairs(modules) do
			if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
				error("[WezMacs] " .. modules_path .. ": must be a dense sequence", 0)
			end
			count = count + 1
			maximum = math.max(maximum, key)
		end
		if count ~= maximum then
			error("[WezMacs] " .. modules_path .. ": must be a dense sequence", 0)
		end
		return modules
	end
end

local function validate_fields(definition, context)
	for _, field in ipairs({ "opts", "keys", "deps", "setup" }) do
		local value = definition[field]
		if value ~= nil and type(value) ~= "function" and (field == "setup" or type(value) ~= "table") then
			local expected = field == "setup" and "a function" or "a table or function"
			return context .. " " .. field .. " must be " .. expected
		end
	end
end

-- Parse module entry (string or table)
local function parse_entry(entry)
	local name = type(entry) == "table" and entry[1] or entry
	if type(name) ~= "string" or not name:find("%S") then
		return nil, "invalid module entry: name must be a non-empty string"
	end
	if type(entry) == "string" then
		return { name = entry }, nil
	elseif type(entry) == "table" then
		local err = validate_fields(entry, name .. ": user")
		if err then
			return nil, err
		end
		return {
			name = entry[1],
			opts = entry.opts,
			keys = entry.keys,
			deps = entry.deps,
			setup = entry.setup,
		},
			nil
	else
		return nil, "invalid module entry: " .. tostring(entry)
	end
end

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

local function has_indices(value)
	for key in pairs(value) do
		if type(key) == "number" then
			return true
		end
	end
	return false
end

-- Maps merge recursively; numeric-key tables (including sequences) replace.
-- An explicit empty table clears a default sequence, not a default map.
-- Keys differ: named groups merge, supplied numeric bindings replace the whole
-- numeric list at that level, and {} clears a key group (or all keys at root).
-- Binding specs replace in full; omitted fields always preserve defaults.
local function deep_merge(a, b, key_map)
	if not a and not b then
		return {}
	elseif not a then
		return clone(b)
	elseif not b then
		return clone(a)
	end
	-- Binding specs are atomic: never combine distinct WezTerm action variants.
	if key_map and (next(b) == nil or a.action ~= nil or a.key ~= nil or b.action ~= nil or b.key ~= nil) then
		return clone(b)
	end
	if not key_map and (has_indices(a) or has_indices(b)) then
		return clone(b)
	end

	local out = clone(a)
	if key_map and has_indices(b) then
		for key in pairs(out) do
			if type(key) == "number" then
				out[key] = nil
			end
		end
	end
	for k, v in pairs(b) do
		if type(v) == "table" and type(out[k]) == "table" then
			out[k] = deep_merge(out[k], v, key_map)
		else
			out[k] = clone(v)
		end
	end

	return out
end

local function evaluate(value, context, ...)
	if type(value) == "function" then
		local success, result = pcall(value, ...)
		if not success then
			error(context .. " failed: " .. tostring(result), 0)
		end
		if type(result) ~= "table" then
			error(context .. " must return a table", 0)
		end
		return result
	end
	return value
end

local function get_field(mod, mod_config, field, ...)
	local context = mod_config.name .. ": "
	local defaults = evaluate(mod[field] or {}, context .. "module " .. field, ...)
	local user = evaluate(mod_config[field], context .. "user " .. field, ...)
	return deep_merge(defaults, user, field == "keys")
end

-- Return the setup function
local function get_setup(mod, mod_config)
	if mod.setup and mod_config.setup then
		return function(config, opts)
			mod.setup(config, opts)
			mod_config.setup(config, opts)
		end
	elseif mod.setup then
		return mod.setup
	elseif mod_config.setup then
		return mod_config.setup
	else
		return function(_, _) end
	end
end

-- Load built-in modules only; dependency lists are metadata, not auto-loaded.
local function load(entry)
	local mod_config, err = parse_entry(entry)
	if err then
		return nil, err
	elseif not mod_config then
		return nil, "unable to parse entry"
	end

	local success, mod = pcall(require, "wezmacs.modules." .. mod_config.name)
	if not success then
		return nil, mod_config.name .. ": require failed: " .. tostring(mod)
	end
	if type(mod) ~= "table" then
		return nil, mod_config.name .. ": module must return a table"
	end
	err = validate_fields(mod, mod_config.name .. ": module")
	if err then
		return nil, err
	end
	local loaded, result = pcall(function()
		local opts = get_field(mod, mod_config, "opts")
		return {
			name = mod_config.name,
			opts = opts,
			deps = get_field(mod, mod_config, "deps", opts),
			keys = get_field(mod, mod_config, "keys", opts),
			setup = get_setup(mod, mod_config),
		}
	end)
	if not loaded then
		return nil, tostring(result)
	end
	wezterm.log_info("[WezMacs] Loaded Module: " .. mod_config.name)
	return result, nil
end

return function(wezmacs_dir)
	return {
		list = list(wezmacs_dir),
		load = load,
	}
end
