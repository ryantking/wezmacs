--[[
  WezMacs Keybindings

  Convert mixed list/map bindings into WezTerm keys and named key tables.
  Numeric entries are direct bindings; mapped action specs are leaves, and
  other mapped tables are menus. Only the root LEADER group adds LEADER mods.

  Example:
    wezmacs.keys.map(config, {
      { key = "r", mods = "CTRL", action = act.ReloadConfiguration },
      LEADER = {
        r = { action = act.ReloadConfiguration, desc = "reload" },
        g = {
          { key = "g", action = act.ActivateCopyMode, desc = "copy" },
          s = { action = act.ActivateCopyMode, desc = "copy" },
        },
      },
    }, "git")
]]

local wezterm = require("wezterm")
local wezterm_act = wezterm.action
local M = {}

-- Paths remain public and module-independent, e.g. LEADER.g.g or CTRL+r.
-- Ownership follows the latest description registered for a path.
M._descriptions = {}
local description_owners = {}

local function record_description(path, desc, module_name)
	M._descriptions[path] = desc
	description_owners[path] = module_name
end

local function resolve_action(action)
	if type(action) == "function" then
		return wezterm.action_callback(action)
	end
	if type(action) == "table" and action.args == nil and action.name == nil and action.action then
		return resolve_action(action.action)
	end
	return action
end

-- Only leaves get this wrapper; generated table activations must stay active.
local function wrap_with_pop_key_table(action)
	if action == "PopKeyTable" then
		return action
	end
	return wezterm.action_callback(function(window, pane)
		window:perform_action(action, pane)
		window:perform_action("PopKeyTable", pane)
	end)
end

local function is_action_spec(value)
	if type(value) ~= "table" then
		return false
	end
	if value.key then
		return true
	end
	if value.action or value.desc then
		for key, item in pairs(value) do
			if key ~= "action" and key ~= "desc" and type(key) == "string" and type(item) == "table" then
				return false
			end
		end
		return true
	end
	return false
end

local function sorted_keys(entries, key_type)
	local result = {}
	for key in pairs(entries) do
		if type(key) == key_type then
			table.insert(result, key)
		end
	end
	table.sort(result)
	return result
end

local function convert_key_map(key_map, module_name)
	local keys = {}
	local key_tables = {}

	local function compile(entries, bindings, prefix, leader)
		local in_table = prefix ~= "" and not leader

		local function add_leaf(key, spec, mapped)
			local mods = leader and "LEADER" or (spec.mods or "")
			local path = prefix == "" and key or prefix .. "." .. key
			if not leader and mods ~= "" then
				path = mods .. "+" .. path
			end
			local desc = spec.desc or (module_name .. "/" .. (leader and "LEADER." or "") .. key)
			record_description(path, desc, module_name)
			local action = resolve_action(spec.action or (mapped and spec or nil))
			table.insert(bindings, {
				key = key,
				mods = mods,
				action = in_table and wrap_with_pop_key_table(action) or action,
			})
		end

		-- Preserve list-before-map precedence, sorting sparse numeric indices too.
		-- LEADER is a mapped prefix group, not a list of direct bindings.
		if not leader then
			for _, index in ipairs(sorted_keys(entries, "number")) do
				local spec = entries[index]
				if type(spec) == "table" and spec.key ~= nil then
					add_leaf(spec.key, spec, false)
				end
			end
		end

		for _, key in ipairs(sorted_keys(entries, "string")) do
			local value = entries[key]
			if key == "LEADER" and prefix == "" then
				if type(value) == "table" and not is_action_spec(value) then
					compile(value, bindings, "LEADER", true)
				end
			elseif is_action_spec(value) then
				add_leaf(key, value, true)
			elseif type(value) == "table" then
				-- Retain established names, including module_LEADER_key.
				local table_name = module_name .. "_" .. (prefix == "" and key or prefix .. "_" .. key)
				if not key_tables[table_name] then
					key_tables[table_name] = { { key = "Escape", action = "PopKeyTable" } }
					table.insert(bindings, {
						key = key,
						mods = leader and "LEADER" or "",
						action = wezterm_act.ActivateKeyTable({
							name = table_name,
							one_shot = false,
							until_unknown = true,
						}),
					})
				end
				local path = prefix == "" and key or prefix .. "." .. key
				compile(value, key_tables[table_name], path, false)
			end
		end
	end

	compile(key_map, keys, "", false)
	return keys, key_tables
end

---@param config table WezTerm config object
---@param key_map table Rendered key map (mixed list/map structure)
---@param module_name string? Module name for key table naming (defaults to unknown)
function M.map(config, key_map, module_name)
	if type(key_map) ~= "table" then
		return
	end
	config.keys = config.keys or {}
	config.key_tables = config.key_tables or {}
	local keys, key_tables = convert_key_map(key_map, module_name or "unknown")
	for _, key in ipairs(keys) do
		table.insert(config.keys, key)
	end
	for name, table_def in pairs(key_tables) do
		config.key_tables[name] = table_def
	end
end

---@return table Map of path -> description
function M.get_descriptions() return M._descriptions end

---@param module_name string Module name
---@return table Map of path -> description
function M.get_module_descriptions(module_name)
	local result = {}
	for path, desc in pairs(M._descriptions) do
		if description_owners[path] == module_name then
			result[path] = desc
		end
	end
	return result
end

return M
