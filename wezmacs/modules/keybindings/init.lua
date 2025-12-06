--[[
  Module: keybindings
  Category: editing
  Description: Core keyboard bindings for pane/tab management, selection, and navigation

  Provides:
  - Pane navigation and management (split, zoom, select)
  - Tab management (new, close, navigate)
  - Quick select mode for URLs, paths, hashes, IPs, UUIDs
  - Character selector and miscellaneous utilities
  - Leader key setup (SUPER+Space, 5 second timeout)

  Configurable flags:
    leader_key - Leader key (default: Space)
    leader_mod - Leader modifier (default: SUPER)
]]

local wezterm = require("wezterm")
local keys_util = require("wezmacs.utils.keys")
local act = wezterm.action
local spec = require("wezmacs.modules.keybindings.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  opts = opts or {}
  local mod = opts.modifier ~= nil and opts or wezmacs.get_module(M._NAME)

  config.leader = { key = mod.leader_key, mods = mod.leader_mod, timeout_milliseconds = 5000 }

  -- ============================================================================
  -- MAIN KEYBINDINGS
  -- ============================================================================

  config.disable_default_key_bindings = true
  config.keys = config.keys or {}
  config.key_tables = config.key_tables or {}

  -- General
  table.insert(config.keys, { key = "r", mods = mod.modifier, action = act.ReloadConfiguration })
  table.insert(config.keys, { key = "r", mods = "LEADER", action = act.ReloadConfiguration })
  table.insert(config.keys, { key = "L", mods = "LEADER", action = act.ShowDebugOverlay })
  table.insert(config.keys, { key = "Enter", mods = "LEADER", action = act.ActivateCommandPalette })
  table.insert(config.keys, { key = "u", mods = "LEADER", action = act.CharSelect })
  table.insert(config.keys, { key = "Space", mods = "LEADER", action = act.QuickSelect })
  table.insert(config.keys, { key = "f", mods = mod.modifier, action = act.Search({CaseInSensitiveString=""}) })
  table.insert(config.keys, { key = "/", mods = "LEADER", action = act.Search({CaseInSensitiveString=""}) })

  table.insert(config.keys, {
    key = "l",
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

  -- Scrollback
  table.insert(config.keys, { key = "PageUp", mods = "SHIFT", action = act.ScrollToPrompt(-1) })
  table.insert(config.keys, { key = "PageDown", mods = "SHIFT", action = act.ScrollToPrompt(1) })
  table.insert(config.keys, { key = "k", mods = mod.modifier, action = act.ClearScrollback("ScrollbackOnly") })
  table.insert(config.keys, { key = "v", mods = "LEADER", action = act.ActivateCopyMode })

  -- Clipboard
  table.insert(config.keys, { key = "c", mods = mod.modifier, action = act.CopyTo("Clipboard") })
  table.insert(config.keys, { key = "v", mods = mod.modifier, action = act.PasteFrom("Clipboard") })
  table.insert(config.keys, { key = "y", mods = "LEADER", action = act.CopyTo("Clipboard") })
  table.insert(config.keys, { key = "p", mods = "LEADER", action = act.PasteFrom("Clipboard") })
  table.insert(config.keys, { key = "Copy",  action = act.CopyTo("Clipboard") })
  table.insert(config.keys, { key = "Paste", action = act.PasteFrom("Clipboard") })
  table.insert(config.keys, { key = "Y", mods = "LEADER", action = act.CopyTo("PrimarySelection") })
  table.insert(config.keys, { key = "P", mods = "LEADER", action = act.PasteFrom("PrimarySelection") })
  table.insert(config.keys, { key = "Insert", mods = "CTRL", action = act.CopyTo("PrimarySelection") })
  table.insert(config.keys, { key = "Insert", mods = "SHIFT", action = act.PasteFrom("PrimarySelection") })

  -- Window Management
  table.insert(config.keys, { key = "n", mods = mod.modifier, action = act.SpawnWindow })
  table.insert(config.keys, { key = "n", mods = "LEADER", action = act.SpawnWindow })
  table.insert(config.keys, { key = "m", mods = mod.modifier, action = act.Hide })
  table.insert(config.keys, { key = "h", mods = mod.modifier, action = act.HideApplication })
  -- LEADER f reserved for file-manager module key table
  table.insert(config.keys, { key = "F", mods = "LEADER", action = act.ToggleFullScreen })
  table.insert(config.keys, { key = "+", mods = mod.modifier, action = act.IncreaseFontSize })
  table.insert(config.keys, { key = "-", mods = mod.modifier, action = act.DecreaseFontSize })
  table.insert(config.keys, { key = "0", mods = mod.modifier, action = act.ResetFontSize })

  -- Tab Management
  table.insert(config.keys, { key = "t", mods = mod.modifier, action = act.SpawnTab("CurrentPaneDomain") })
  -- LEADER t reserved for domains module key table
  table.insert(config.keys, { key = "T", mods = "LEADER", action = act.SpawnTab("DefaultDomain") })
  table.insert(config.keys, { key = "w", mods = mod.modifier, action = act.CloseCurrentTab({ confirm = false }) })
  table.insert(config.keys, { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) })
  table.insert(config.keys, { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) })
  table.insert(config.keys, { key = "[", mods = mod.modifier, action = act.ActivateTabRelative(-1) })
  table.insert(config.keys, { key = "]", mods = mod.modifier, action = act.ActivateTabRelative(1) })
  table.insert(config.keys, { key = "{", mods = mod.modifier, action = act.MoveTabRelative(-1) })
  table.insert(config.keys, { key = "}", mods = mod.modifier, action = act.MoveTabRelative(1) })
  table.insert(config.keys, { key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) })
  table.insert(config.keys, { key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) })
  table.insert(config.keys, { key = "{", mods = "LEADER", action = act.MoveTabRelative(-1) })
  table.insert(config.keys, { key = "}", mods = "LEADER", action = act.MoveTabRelative(1) })
  table.insert(config.keys, { key = "PageUp", mods = "CTRL", action = act.ActivateTabRelative(-1) })
  table.insert(config.keys, { key = "PageDown", mods = "CTRL", action = act.ActivateTabRelative(1) })
  table.insert(config.keys, { key = "PageUp", mods = "CTRL|SHIFT", action = act.MoveTabRelative(-1) })
  table.insert(config.keys, { key = "PageDown", mods = "CTRL|SHIFT", action = act.MoveTabRelative(1) })

  for i = 1, 9 do
    table.insert(config.keys, { key = tostring(i), mods = mod.modifier, action = act.ActivateTab(i) })
    table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i) })
  end

  -- Pane Management
  table.insert(config.keys, { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) })
  table.insert(config.keys, { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) })
  table.insert(config.keys, { key = "z", mods = "LEADER", action = act.TogglePaneZoomState })
  table.insert(config.keys, { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) })
  table.insert(config.keys, { key = "LeftArrow", mods = "CTRL", action = act.ActivatePaneDirection("Left") })
  table.insert(config.keys, { key = "RightArrow", mods = "CTRL", action = act.ActivatePaneDirection("Right") })
  table.insert(config.keys, { key = "UpArrow", mods = "CTRL", action = act.ActivatePaneDirection("Up") })
  table.insert(config.keys, { key = "DownArrow", mods = "CTRL", action = act.ActivatePaneDirection("Down") })
  table.insert(config.keys, { key = "LeftArrow", mods = "CTRL|SUPER", action = act.AdjustPaneSize({ "Left", 2 }) })
  table.insert(config.keys, { key = "RightArrow", mods = "CTRL|SUPER", action = act.AdjustPaneSize({ "Right", 2 }) })
  table.insert(config.keys, { key = "UpArrow", mods = "CTRL|SUPER", action = act.AdjustPaneSize({ "Up", 2 }) })
  table.insert(config.keys, { key = "DownArrow", mods = "CTRL|SUPER", action = act.AdjustPaneSize({ "Down", 2 }) })

  table.insert(config.keys, {
    key = "N",
    mods = "LEADER",
    action = wezterm.action_callback(function(_, pane)
      pane:move_to_new_tab()
    end),
  })
  table.insert(config.keys, {
    key = "W",
    mods = "LEADER",
    action = wezterm.action_callback(function(_, pane)
      pane:move_to_new_window()
    end),
  })
end

return M
