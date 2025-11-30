--[[
  WezMacs Keybinding Utilities

  Helper functions for keybinding modules to reduce boilerplate
  and provide consistent patterns across modules.
]]

local wezterm = require("wezterm")

local M = {}

-- Convert modifier name strings to wezterm format
-- Handles special keywords like "LEADER"
---@param mod_string string Modifier string (e.g., "CMD", "CTRL|SHIFT", "LEADER")
---@param leader_key string|nil Leader key if LEADER is used (default: "Space")
---@param leader_mod string|nil Leader modifier if LEADER is used (default: "CMD")
---@return string WezTerm modifier string
function M.mod_name(mod_string, leader_key, leader_mod)
  if mod_string == "LEADER" then
    return leader_mod or "CMD"
  end

  -- Handle pipe-separated modifiers
  if mod_string:find("|") then
    return mod_string
  end

  return mod_string
end

-- Create a keybinding tuple
---@param key string Key name
---@param mods string Modifier string
---@param action any WezTerm action
---@return table Keybinding table
function M.chord(key, mods, action)
  return {
    key = key,
    mods = mods,
    action = action,
  }
end

-- Create a leader key chord helper
---@param key string Key name
---@param leader_key string Leader key
---@param leader_mod string Leader modifier
---@param action any WezTerm action
---@return table Keybinding table with leader chord
function M.leader_chord(key, leader_key, leader_mod, action)
  return M.chord(key, "LEADER", action)
end

-- Create a key table with boilerplate setup
-- Automatically adds Escape to close the table
---@param name string Key table name
---@param bindings table List of key bindings
---@param opts table Optional configuration
---@return table Configured key table
function M.key_table(name, bindings, opts)
  opts = opts or {}
  local table_config = {}

  -- Add all provided bindings
  for _, binding in ipairs(bindings) do
    table.insert(table_config, binding)
  end

  -- Always add Escape to exit (unless explicitly disabled)
  if opts.no_escape ~= true then
    table.insert(table_config, { key = "Escape", action = "PopKeyTable" })
  end

  -- Add Enter to exit if requested
  if opts.exit_on_enter then
    table.insert(table_config, { key = "Enter", action = "PopKeyTable" })
  end

  return table_config
end

-- Safely append keys to config.keys without losing existing keys
---@param config table WezTerm config object
---@param new_keys table List of new keybindings
function M.apply_to_keys(config, new_keys)
  if not config.keys then
    config.keys = {}
  end

  for _, key_binding in ipairs(new_keys) do
    table.insert(config.keys, key_binding)
  end
end

-- Safely append key tables to config without losing existing tables
---@param config table WezTerm config object
---@param tables table Map of table_name = table_config
function M.apply_to_key_tables(config, tables)
  if not config.key_tables then
    config.key_tables = {}
  end

  for name, table_config in pairs(tables) do
    config.key_tables[name] = table_config
  end
end

-- Helper to create a simple action callback binding
---@param key string Key name
---@param mods string Modifier string
---@param callback function Action callback function(window, pane)
---@return table Keybinding with callback
function M.action_chord(key, mods, callback)
  return M.chord(key, mods, wezterm.action_callback(callback))
end

-- Helper to create a SpawnCommand action
---@param key string Key name
---@param mods string Modifier string
---@param args table Command and arguments to spawn
---@param opts table Optional SpawnCommand options
---@return table Keybinding for spawn command
function M.spawn_chord(key, mods, args, opts)
  opts = opts or {}
  local action_opts = {
    args = args,
  }

  -- Merge in optional fields
  for k, v in pairs(opts) do
    action_opts[k] = v
  end

  return M.chord(key, mods, wezterm.action.SpawnCommandInNewTab(action_opts))
end

-- Helper to navigate panes
---@param key string Arrow key direction (UpArrow, DownArrow, LeftArrow, RightArrow)
---@param mods string Modifier string
---@return table Keybinding for pane navigation
function M.pane_nav(key, mods)
  -- Convert arrow key to direction
  local direction_map = {
    UpArrow = "Up",
    DownArrow = "Down",
    LeftArrow = "Left",
    RightArrow = "Right",
  }

  local direction = direction_map[key]
  if not direction then
    error("Invalid arrow key: " .. key)
  end

  return M.chord(key, mods, wezterm.action.ActivatePaneDirection(direction))
end

-- Helper to split panes
---@param direction string "Up" | "Down" | "Left" | "Right"
---@param size number|table Size as percentage or table
---@return table WezTerm SplitPane action
function M.split_pane_action(direction, size)
  size = size or { Percent = 50 }
  return wezterm.action.SplitPane({
    direction = direction,
    size = size,
  })
end

-- Helper to create a tab action
---@param key string Key name
---@param mods string Modifier string
---@param action_name string Action type ("new" | "close" | "next" | "prev")
---@return table Keybinding for tab action
function M.tab_action(key, mods, action_name)
  local action_map = {
    new = wezterm.action.SpawnTab("CurrentPaneDomain"),
    close = wezterm.action.CloseCurrentTab({ confirm = false }),
    next = wezterm.action.ActivateTabRelative(1),
    prev = wezterm.action.ActivateTabRelative(-1),
  }

  local action = action_map[action_name]
  if not action then
    error("Invalid tab action: " .. action_name)
  end

  return M.chord(key, mods, action)
end

return M
