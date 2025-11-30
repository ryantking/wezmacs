--[[
  Module: keybindings
  Category: editing
  Description: Core keyboard bindings for pane/tab management, selection, and navigation

  Provides:
  - Pane navigation and management (split, zoom, select)
  - Tab management (new, close, navigate)
  - Quick select mode for URLs, paths, hashes, IPs, UUIDs
  - Character selector and miscellaneous utilities
  - Leader key setup (CMD+Space, 5 second timeout)

  Configurable flags:
    leader_key - Leader key (default: Space)
    leader_mod - Leader modifier (default: CMD)
]]

local wezterm = require("wezterm")
local keys_util = require("wezmacs.utils.keys")
local act = wezterm.action

local M = {}

M._NAME = "keybindings"
M._CATEGORY = "editing"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Core keyboard bindings for pane and tab management"
M._EXTERNAL_DEPS = {}
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  leader_key = "Space",
  leader_mod = "CMD",
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

function M.apply_to_config(config, state)
  config.disable_default_key_bindings = false
  config.leader = { key = state.leader_key, mods = state.leader_mod, timeout_milliseconds = 5000 }

  -- ============================================================================
  -- KEY TABLES (Modal/Submenu Keybindings)
  -- ============================================================================

  config.key_tables = config.key_tables or {}

  -- Resize pane mode: LEADER+SHIFT+Arrow activates, then use arrows to resize
  config.key_tables.resize_pane = {
    { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 2 }) },
    { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 2 }) },
    { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
    { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter", action = "PopKeyTable" },
  }

  -- ============================================================================
  -- MAIN KEYBINDINGS
  -- ============================================================================

  config.keys = config.keys or {}

  -- Pane Management
  table.insert(config.keys, { key = "-", mods = "LEADER", action = act.SplitPane({ direction = "Down", size = { Percent = 30 } }) })
  table.insert(config.keys, { key = "|", mods = "LEADER|SHIFT", action = act.SplitPane({ direction = "Right", size = { Percent = 25 } }) })
  table.insert(config.keys, { key = "z", mods = "LEADER", action = act.TogglePaneZoomState })
  table.insert(config.keys, { key = "p", mods = "LEADER", action = act.PaneSelect({}) })
  table.insert(config.keys, { key = "P", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) })
  table.insert(config.keys, {
    key = "n",
    mods = "LEADER",
    action = wezterm.action_callback(function(_, pane)
      pane:move_to_new_tab()
    end),
  })
  table.insert(config.keys, {
    key = "N",
    mods = "LEADER",
    action = wezterm.action_callback(function(_, pane)
      pane:move_to_new_window()
    end),
  })

  -- Tab Management
  table.insert(config.keys, { key = "t", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") })
  table.insert(config.keys, { key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) })

  -- Pane Navigation
  table.insert(config.keys, { key = "LeftArrow", mods = "CTRL", action = act.ActivatePaneDirection("Left") })
  table.insert(config.keys, { key = "RightArrow", mods = "CTRL", action = act.ActivatePaneDirection("Right") })
  table.insert(config.keys, { key = "UpArrow", mods = "CTRL", action = act.ActivatePaneDirection("Up") })
  table.insert(config.keys, { key = "DownArrow", mods = "CTRL", action = act.ActivatePaneDirection("Down") })

  -- Pane Resizing (LEADER+SHIFT+Arrow → sticky resize mode)
  table.insert(config.keys, {
    key = "LeftArrow",
    mods = "LEADER|SHIFT",
    action = act.Multiple({
      act.AdjustPaneSize({ "Left", 2 }),
      act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
    }),
  })
  table.insert(config.keys, {
    key = "RightArrow",
    mods = "LEADER|SHIFT",
    action = act.Multiple({
      act.AdjustPaneSize({ "Right", 2 }),
      act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
    }),
  })
  table.insert(config.keys, {
    key = "UpArrow",
    mods = "LEADER|SHIFT",
    action = act.Multiple({
      act.AdjustPaneSize({ "Up", 2 }),
      act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
    }),
  })
  table.insert(config.keys, {
    key = "DownArrow",
    mods = "LEADER|SHIFT",
    action = act.Multiple({
      act.AdjustPaneSize({ "Down", 2 }),
      act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
    }),
  })

  -- Utility & Selection
  table.insert(config.keys, {
    key = "q",
    mods = "LEADER",
    action = act.QuickSelectArgs({
      label = "open url/path/hash",
      patterns = {
        "https?://\\S+",
        "git@[\\w.-]+:[\\w./-]+",
        "file://\\S+",
        "[~./]\\S+/\\S+",
        "/[a-zA-Z0-9_/-]+",
        "\\b[a-f0-9]{7,40}\\b",
        "\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b",
        "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
      },
    }),
  })
  table.insert(config.keys, {
    key = "e",
    mods = "LEADER",
    action = act.CharSelect({
      copy_on_select = true,
      copy_to = "ClipboardAndPrimarySelection",
    }),
  })

  -- Scrolling & Misc
  table.insert(config.keys, { key = "UpArrow", mods = "SHIFT", action = act.ScrollToPrompt(-1) })
  table.insert(config.keys, { key = "DownArrow", mods = "SHIFT", action = act.ScrollToPrompt(1) })
  table.insert(config.keys, { key = "Enter", mods = "LEADER", action = act.ToggleFullScreen })
  table.insert(config.keys, { key = "L", mods = "LEADER", action = act.ShowDebugOverlay })

  -- Claude Prompt Handling
  table.insert(config.keys, { key = "Enter", mods = "SHIFT", action = act.SendString("\\x1b\\r") })

  -- Disable Default Assignments
  table.insert(config.keys, { key = "Tab", mods = "CTRL", action = act.DisableDefaultAssignment })
  table.insert(config.keys, { key = "Tab", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment })
end

return M
