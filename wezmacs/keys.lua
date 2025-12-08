--[[
  WezMacs Keybindings

  Handles mixed list/map format for keybindings and converts to WezTerm format.
  Supports descriptions for help text generation.

  Usage:
    local wezmacs = require('wezmacs')
    wezmacs.keys.map(config, key_map, module_name)

  Format:
    {
      -- List items (numeric keys) are direct keybindings
      { key = "r", mods = "CTRL", action = act.ReloadConfiguration, desc = "wezterm/reload" },
      { key = "f", mods = "CTRL", action = act.Search(...), desc = "wezterm/search" },
      
      -- String keys map to nested key tables
      LEADER = {
        -- LEADER is special: keys here get mods = "LEADER" directly
        -- Direct bindings use action spec format
        r = { action = act.ReloadConfiguration, desc = "wezterm/reload" },
        -- Nested key tables contain list items
        g = {
          { key = "g", action = act.SpawnCommandInNewTab(...), desc = "git/lazygit" },
          { key = "s", action = act.SmartSplit("git status"), desc = "git/status" },
        },
      },
    }
]]

local wezterm = require("wezterm")
local wezterm_act = wezterm.action

local M = {}

-- Store keybinding descriptions for help text
-- Format: { ["LEADER.g.g"] = "git/lazygit-split", ... }
M._descriptions = {}

-- Resolve action from function or WezTerm action
local function resolve_action(action)
	-- Handle WezTerm action strings directly
	if type(action) == "string" and (action == "PopKeyTable" or action == "ActivateCopyMode") then
		return action
	end

	-- Handle WezTerm action tables
	if type(action) == "table" then
		-- If it has args or name, it's likely a WezTerm action
		if action.args ~= nil or action.name ~= nil then
			return action
		end
		-- Check if it looks like an action spec: { action = ..., desc = "..." }
		if action.action then
			return resolve_action(action.action)
		end
		-- Otherwise assume it's a WezTerm action table
		return action
	end

	-- Handle functions - wrap in action_callback
	if type(action) == "function" then
		return wezterm.action_callback(action)
	end

	return action
end

-- Wrap an action to exit key table after execution
-- This ensures that after executing an action from within a key table,
-- WezTerm exits the key table context
local function wrap_with_pop_key_table(action)
	local resolved = resolve_action(action)

	-- If it's already PopKeyTable, don't wrap
	if resolved == "PopKeyTable" then
		return resolved
	end

	-- Wrap in a callback that executes the action and then pops the key table
	return wezterm.action_callback(function(window, pane)
		-- Execute the original action
		-- All resolved actions should be executable via perform_action
		-- Functions returned by resolve_action are already wrapped in action_callback
		if type(resolved) == "function" then
			-- It's already an action_callback function, call it directly
			resolved(window, pane)
		else
			-- It's a WezTerm action (table or string), execute it
			window:perform_action(resolved, pane)
		end

		-- Pop the key table after the action completes
		window:perform_action("PopKeyTable", pane)
	end)
end

-- Check if a value is a keybinding spec (has key field)
local function is_keybinding_spec(value) return type(value) == "table" and value.key ~= nil end

-- Check if a value is an action spec (has action or desc, but not nested tables)
local function is_action_spec(value)
	if type(value) ~= "table" then
		return false
	end

	-- If it has a key field, it's a keybinding spec
	if value.key then
		return true
	end

	-- If it has action or desc, check if it has nested tables
	if value.action or value.desc then
		-- Check if it has nested string keys (would be a nested table)
		for k, v in pairs(value) do
			if k ~= "action" and k ~= "desc" and type(k) == "string" and type(v) == "table" then
				return false -- Has nested tables, not an action spec
			end
		end
		return true -- Has action/desc and no nested tables
	end

	return false
end

-- Check if a value is a nested key table (has string keys that aren't action specs)
local function is_nested_table(value)
	if type(value) ~= "table" then
		return false
	end

	-- If it's an action spec, it's not a nested table
	if is_action_spec(value) then
		return false
	end

	-- Check if it has string keys (nested tables)
	for k, v in pairs(value) do
		if type(k) == "string" then
			return true
		end
	end

	return false
end

-- Convert mixed list/map format to WezTerm keybindings
-- Handles: { { key = "r", mods = "CTRL", ... }, LEADER = { r = { ... } } }
---@param key_map table Mixed list/map of keybindings
---@param module_name string Module name for description prefix
---@param table_prefix string Current key table prefix (e.g., "LEADER.g")
---@return table, table Keys array and key_tables dict
local function convert_key_map(key_map, module_name, table_prefix)
	local keys = {}
	local key_tables = {}
	table_prefix = table_prefix or ""

	-- Separate list items (numeric keys) from map items (string keys)
	local list_items = {}
	local map_items = {}

	for k, v in pairs(key_map) do
		if type(k) == "number" then
			table.insert(list_items, v)
		elseif type(k) == "string" then
			map_items[k] = v
		end
	end

	-- Process list items (direct keybindings)
	for _, item in ipairs(list_items) do
		if is_keybinding_spec(item) then
			local key = item.key
			local mods = item.mods or ""
			local action = resolve_action(item.action)
			local desc = item.desc or (module_name .. "/" .. key)

			-- Store description
			local path = table_prefix == "" and key or table_prefix .. "." .. key
			if mods ~= "" then
				path = mods .. "+" .. path
			end
			M._descriptions[path] = desc

			-- Add keybinding
			table.insert(keys, {
				key = key,
				mods = mods,
				action = action,
			})
		end
	end

	-- Process map items (nested key tables)
	for key_name, value in pairs(map_items) do
		if key_name == "LEADER" then
			-- LEADER is special: process keys directly with mods = "LEADER"
			if is_nested_table(value) then
				-- Process LEADER subtable
				for sub_key, sub_value in pairs(value) do
					if is_nested_table(sub_value) then
						-- Nested key table: LEADER+sub_key activates table
						local table_name = module_name .. "_LEADER_" .. sub_key

						-- Create key table if it doesn't exist
						if not key_tables[table_name] then
							key_tables[table_name] = {}
							-- Add Escape to exit
							table.insert(key_tables[table_name], {
								key = "Escape",
								action = "PopKeyTable",
							})

							-- Add activation keybinding with mods = "LEADER"
							table.insert(keys, {
								key = sub_key,
								mods = "LEADER",
								action = wezterm_act.ActivateKeyTable({
									name = table_name,
									one_shot = false,
									until_unknown = true,
								}),
							})
						end

						-- Process nested table recursively
						local nested_keys, nested_tables = convert_key_map(sub_value, module_name, "LEADER." .. sub_key)

						-- Add keys to the key table, wrapping actions to exit the table
						for _, k in ipairs(nested_keys) do
							local wrapped_key = {
								key = k.key,
								mods = k.mods,
								action = wrap_with_pop_key_table(k.action),
							}
							table.insert(key_tables[table_name], wrapped_key)
						end

						-- Merge nested key tables
						for k, v in pairs(nested_tables) do
							key_tables[k] = v
						end
					elseif is_action_spec(sub_value) then
						-- Direct keybinding under LEADER
						local action = resolve_action(sub_value.action or sub_value)
						local desc = sub_value.desc or (module_name .. "/LEADER." .. sub_key)

						-- Store description
						M._descriptions["LEADER." .. sub_key] = desc

						-- Add keybinding with mods = "LEADER"
						table.insert(keys, {
							key = sub_key,
							mods = "LEADER",
							action = action,
						})
					elseif type(sub_value) == "table" then
						-- List of keybinding specs: LEADER+sub_key activates table with list items
						local table_name = module_name .. "_LEADER_" .. sub_key

						-- Create key table if it doesn't exist
						if not key_tables[table_name] then
							key_tables[table_name] = {}
							-- Add Escape to exit
							table.insert(key_tables[table_name], {
								key = "Escape",
								action = "PopKeyTable",
							})

							-- Add activation keybinding with mods = "LEADER"
							table.insert(keys, {
								key = sub_key,
								mods = "LEADER",
								action = wezterm_act.ActivateKeyTable({
									name = table_name,
									one_shot = false,
									until_unknown = true,
								}),
							})
						end

						-- Process list items recursively
						local nested_keys, nested_tables = convert_key_map(sub_value, module_name, "LEADER." .. sub_key)

						-- Add keys to the key table, wrapping actions to exit the table
						for _, k in ipairs(nested_keys) do
							local wrapped_key = {
								key = k.key,
								mods = k.mods,
								action = wrap_with_pop_key_table(k.action),
							}
							table.insert(key_tables[table_name], wrapped_key)
						end

						-- Merge nested key tables
						for k, v in pairs(nested_tables) do
							key_tables[k] = v
						end
					end
				end
			end
		else
			-- Regular nested key table
			if is_nested_table(value) then
				local table_name = module_name .. "_" .. (table_prefix == "" and key_name or table_prefix .. "_" .. key_name)

				-- Create key table if it doesn't exist
				if not key_tables[table_name] then
					key_tables[table_name] = {}
					-- Add Escape to exit
					table.insert(key_tables[table_name], {
						key = "Escape",
						action = "PopKeyTable",
					})

					-- Add activation keybinding (no mods for top-level key tables)
					local activation_mods = ""
					if table_prefix ~= "" then
						-- Extract mods from prefix (e.g., "LEADER" from "LEADER.g")
						local parts = {}
						for part in table_prefix:gmatch("[^%.]+") do
							table.insert(parts, part)
						end
						activation_mods = parts[1] or ""
					end

					table.insert(keys, {
						key = key_name,
						mods = activation_mods,
						action = wezterm_act.ActivateKeyTable({
							name = table_name,
							one_shot = false,
							until_unknown = true,
						}),
					})
				end

				-- Process nested table recursively
				local nested_keys, nested_tables =
					convert_key_map(value, module_name, table_prefix == "" and key_name or table_prefix .. "." .. key_name)

				-- Add keys to the key table, wrapping actions to exit the table
				for _, k in ipairs(nested_keys) do
					local wrapped_key = {
						key = k.key,
						mods = k.mods,
						action = wrap_with_pop_key_table(k.action),
					}
					table.insert(key_tables[table_name], wrapped_key)
				end

				-- Merge nested key tables
				for k, v in pairs(nested_tables) do
					key_tables[k] = v
				end
			end
		end
	end

	return keys, key_tables
end

-- Map keybindings from a rendered table structure
-- This is a simpler interface that takes the already-rendered key map
---@param config table WezTerm config object
---@param key_map table Rendered key map (mixed list/map structure)
---@param module_name string Module name for key table naming
function M.map(config, key_map, module_name)
	if not key_map or type(key_map) ~= "table" then
		return
	end

	config.keys = config.keys or {}
	config.key_tables = config.key_tables or {}

	local keys, key_tables = convert_key_map(key_map, module_name or "unknown", "")

	-- Add keys to config
	for _, key in ipairs(keys) do
		table.insert(config.keys, key)
	end

	-- Add key tables to config
	for name, table_def in pairs(key_tables) do
		config.key_tables[name] = table_def
	end
end

-- Get all keybinding descriptions
---@return table Map of path -> description
function M.get_descriptions() return M._descriptions end

-- Get descriptions for a specific module
---@param module_name string Module name
---@return table Map of path -> description
function M.get_module_descriptions(module_name)
	local result = {}
	for path, desc in pairs(M._descriptions) do
		if path:match("^" .. module_name) or path:match(module_name .. "/") then
			result[path] = desc
		end
	end
	return result
end

return M
