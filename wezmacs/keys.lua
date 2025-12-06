--[[
  WezMacs Keybindings

  Handles nested map format for keybindings and converts to WezTerm format.
  Supports descriptions for help text generation.

  Usage:
    local wezmacs = require('wezmacs')
    wezmacs.keys.map(config, key_map, module_name)

  Format: { LEADER = { g = { g = { action = ..., desc = "..." } } } }
  Creates: LEADER+g activates key table "git_LEADER_g", then g in table triggers action
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
    if action.desc then
      -- Check if it has nested tables (not an action spec)
      local has_nested = false
      for k, v in pairs(action) do
        if k ~= "desc" and k ~= "action" and type(v) == "table" then
          has_nested = true
          break
        end
      end
      if not has_nested then
        -- This is an action spec without explicit action field, use the table itself
        return action
      end
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

-- Check if a table is an action spec (has action or desc but no nested tables)
local function is_action_spec(value)
  if type(value) ~= "table" then
    return false
  end
  
  -- If it has action field, it's definitely an action spec
  if value.action then
    return true
  end
  
  -- If it has desc but no nested tables, it's an action spec
  if value.desc then
    for k, v in pairs(value) do
      if k ~= "desc" and k ~= "action" and type(v) == "table" then
        return false  -- Has nested tables, not an action spec
      end
    end
    return true
  end
  
  return false
end

-- Convert nested map to WezTerm keybindings
-- Handles: { LEADER = { g = { g = { action = ..., desc = "..." } } } }
---@param key_map table Nested map of keybindings
---@param module_name string Module name for description prefix
---@param mods string Current modifier (e.g., "LEADER")
---@param path string Current path (e.g., "LEADER.g")
---@return table, table Keys array and key_tables dict
local function convert_nested_map(key_map, module_name, mods, path)
  local keys = {}
  local key_tables = {}
  mods = mods or ""
  path = path or ""

  for key, value in pairs(key_map) do
    local current_path = path == "" and key or path .. "." .. key

    if is_action_spec(value) then
      -- This is a leaf node - an action
      local action = value.action or value
      local desc = value.desc or (module_name .. "/" .. key)
      
      -- Store description
      M._descriptions[current_path] = desc

      -- If path has a dot, we need to create a key table
      -- e.g., "LEADER.g" means LEADER+g activates table, then g triggers action
      if path:match("%.") then
        -- Extract table name from path (e.g., "LEADER.g" -> "git_LEADER_g")
        local table_name = module_name .. "_" .. path:gsub("[^%w]", "_")
        
        -- Create key table if it doesn't exist
        if not key_tables[table_name] then
          key_tables[table_name] = {}
          -- Add Escape to exit
          table.insert(key_tables[table_name], {
            key = "Escape",
            action = "PopKeyTable",
          })
          
          -- Extract activation key and mods from path
          -- path is like "LEADER.g", so activation is LEADER+g
          local parts = {}
          for part in path:gmatch("[^.]+") do
            table.insert(parts, part)
          end
          local activation_mods = parts[1]  -- "LEADER"
          local activation_key = parts[2]   -- "g"
          
          -- Add activation keybinding if not already added
          local already_added = false
          for _, k in ipairs(keys) do
            if k.key == activation_key and k.mods == activation_mods then
              already_added = true
              break
            end
          end
          if not already_added then
            table.insert(keys, {
              key = activation_key,
              mods = activation_mods,
              action = wezterm_act.ActivateKeyTable({
                name = table_name,
                one_shot = false,
                until_unknown = true,
              }),
            })
          end
        end
        
        -- Add key to table
        table.insert(key_tables[table_name], {
          key = key,
          action = resolve_action(action),
        })
      else
        -- Direct keybinding (no nested path)
        table.insert(keys, {
          key = key,
          mods = mods,
          action = resolve_action(action),
        })
      end
    else
      -- This is a nested map - recurse
      -- Determine mods for next level
      local next_mods = mods
      if mods == "" then
        -- First level is modifier (e.g., "LEADER")
        next_mods = key
      end
      
      local nested_keys, nested_tables = convert_nested_map(value, module_name, next_mods, current_path)
      
      -- Merge nested tables
      for k, v in pairs(nested_tables) do
        key_tables[k] = v
      end
      
      -- Add nested keys
      for _, k in ipairs(nested_keys) do
        table.insert(keys, k)
      end
    end
  end

  return keys, key_tables
end

-- Apply nested keybindings from module spec
---@param config table WezTerm config object
---@param module_spec table Module spec with keys (table or function)
---@param opts table Module options (passed to keys function if it's a function)
function M.apply_keys(config, module_spec, opts)
  if not module_spec.keys then
    return
  end

  local key_map
  if type(module_spec.keys) == "function" then
    -- Keys is a function - call it with opts
    key_map = module_spec.keys(opts or {})
  elseif type(module_spec.keys) == "table" then
    -- Keys is a table - use it directly
    key_map = module_spec.keys
  else
    return
  end

  if not key_map or type(key_map) ~= "table" then
    return
  end

  config.keys = config.keys or {}
  config.key_tables = config.key_tables or {}

  local keys, key_tables = convert_nested_map(key_map, module_spec.name or "unknown", "", "")

  -- Add keys to config
  for _, key in ipairs(keys) do
    table.insert(config.keys, key)
  end

  -- Add key tables to config
  for name, table_def in pairs(key_tables) do
    config.key_tables[name] = table_def
  end
end

-- Map keybindings from a rendered table structure
-- This is a simpler interface that takes the already-rendered key map
---@param config table WezTerm config object
---@param key_map table Rendered key map (nested table structure)
---@param module_name string Module name for key table naming
function M.map(config, key_map, module_name)
  if not key_map or type(key_map) ~= "table" then
    return
  end

  config.keys = config.keys or {}
  config.key_tables = config.key_tables or {}

  local keys, key_tables = convert_nested_map(key_map, module_name or "unknown", "", "")

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
function M.get_descriptions()
  return M._descriptions
end

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
