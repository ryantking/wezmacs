--[[
  WezMacs Keybindings Library

  Provides declarative API for creating keybindings and key tables.
  Eliminates boilerplate in module definitions.
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Check if a value is a WezTerm action table or string
-- WezTerm actions can be:
--   - String actions: "PopKeyTable", "ActivateCopyMode", etc.
--   - Action tables: created via wezterm.action.* functions
--   - Action callbacks: functions wrapped in wezterm.action_callback()
local function is_wezterm_action(value)
  -- String actions
  if type(value) == "string" and (value == "PopKeyTable" or value == "ActivateCopyMode") then
    return true
  end

  -- Action tables (created by wezterm.action.*)
  if type(value) == "table" then
    -- WezTerm action tables are typically simple tables with action data
    -- They don't have common config keys like "enabled", "features", etc.
    -- Check if it looks like a config table (has common config keys)
    local config_keys = { "enabled", "features", "opts", "keys", "dependencies" }
    for _, key in ipairs(config_keys) do
      if value[key] ~= nil then
        return false  -- Looks like a config table, not an action
      end
    end
    -- If it's a table without config keys, and has "args" or looks like an action, assume it's an action
    -- This is a heuristic - WezTerm actions often have "args" field
    if value.args ~= nil or value.name ~= nil then
      return true
    end
    -- If table is empty or has numeric indices only, it's probably not an action
    -- Otherwise, assume it might be an action (safer to pass through)
    local has_string_keys = false
    for k, _ in pairs(value) do
      if type(k) == "string" then
        has_string_keys = true
        break
      end
    end
    return has_string_keys
  end

  return false
end

-- Resolve action from function or WezTerm action
-- Accepts:
--   - function (direct callback) - wraps in wezterm.action_callback()
--   - WezTerm action table/string (pass through)
---@param action function|table|string Action specification
---@return function|table|string Resolved action
function M.resolve_action(action)
  -- Handle WezTerm action tables or strings directly
  if is_wezterm_action(action) or type(action) == "string" and (action == "PopKeyTable" or action == "ActivateCopyMode") then
    return action
  end

  if type(action) == "function" then
    return wezterm.action_callback(action)
  end

  -- Pass through other types
  return action
end

-- Create a submenu (key table) from declarative spec
---@param config table WezTerm config object
---@param spec table Key spec with leader, submenu, and bindings
function M.create_submenu(config, spec)
  local name = spec.submenu
  local leader_key = spec.leader
  local leader_mods = spec.leader_mods or "LEADER"

  if not name or not leader_key then
    error("Submenu spec must have 'submenu' and 'leader' fields")
  end

  -- Initialize key_tables if needed
  config.key_tables = config.key_tables or {}
  config.key_tables[name] = {}

  -- Build key table from bindings
  for _, binding in ipairs(spec.bindings or {}) do
    if binding.enabled ~= false then
      -- Allow disabling individual keys
      table.insert(config.key_tables[name], {
        key = binding.key,
        action = M.resolve_action(binding.action),
      })
    end
  end

  -- Always add Escape to exit submenu
  table.insert(config.key_tables[name], {
    key = "Escape",
    action = "PopKeyTable",
  })

  -- Add leader key to activate submenu
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = leader_key,
    mods = leader_mods,
    action = act.ActivateKeyTable({
      name = name,
      one_shot = false,
      until_unknown = true,
    }),
  })
end

-- Add direct keybinding (not in submenu)
---@param config table WezTerm config object
---@param spec table Key spec with key, mods, action
function M.add_key(config, spec)
  config.keys = config.keys or {}

  if spec.enabled ~= false then
    table.insert(config.keys, {
      key = spec.key,
      mods = spec.mods,
      action = M.resolve_action(spec.action),
    })
  end
end

-- Process all keybindings from module spec
---@param config table WezTerm config object
---@param module_spec table Module spec with keys array
function M.apply_keys(config, module_spec)
  if not module_spec.keys then
    return
  end

  for _, key_spec in ipairs(module_spec.keys) do
    if key_spec.submenu then
      -- Submenu (key table)
      M.create_submenu(config, key_spec)
    else
      -- Direct keybinding
      M.add_key(config, key_spec)
    end
  end
end

return M
