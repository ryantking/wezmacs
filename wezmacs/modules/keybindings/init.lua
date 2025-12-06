--[[
  Module: keybindings
  Category: editing
  Description: Core keyboard bindings for pane/tab management, selection, and navigation
]]

local wezmacs = require("wezmacs")
local act = wezmacs.action
local wezterm = require("wezterm")

return {
  name = "keybindings",
  category = "editing",
  description = "Core keyboard bindings for pane and tab management",

  deps = {},

  opts = function()
    return {
      modifier = "CTRL|SHIFT",
      leader_key = "Space",
      leader_mod = "SUPER",
    }
  end,

  keys = {},

  enabled = true,

  priority = 100,  -- High priority, loads early

  setup = function(config, opts)
    local wezmacs = require("wezmacs")
    local leader_key = opts.leader_key or wezmacs.config.leader_key or "Space"
    local leader_mod = opts.leader_mod or wezmacs.config.leader_mod or "CTRL"
    config.leader = { key = leader_key, mods = leader_mod, timeout_milliseconds = 5000 }

    -- ============================================================================
    -- MAIN KEYBINDINGS
    -- ============================================================================

    config.disable_default_key_bindings = true
    config.keys = config.keys or {}
    config.key_tables = config.key_tables or {}

    local mod = opts.modifier

    -- General
    table.insert(config.keys, { key = "r", mods = mod, action = wezterm.action.ReloadConfiguration })
    table.insert(config.keys, { key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration })
    table.insert(config.keys, { key = "L", mods = "LEADER", action = wezterm.action.ShowDebugOverlay })
    table.insert(config.keys, { key = "Enter", mods = "LEADER", action = wezterm.action.ActivateCommandPalette })
    table.insert(config.keys, { key = "u", mods = "LEADER", action = wezterm.action.CharSelect })
    table.insert(config.keys, { key = "Space", mods = "LEADER", action = wezterm.action.QuickSelect })
    table.insert(config.keys, { key = "f", mods = mod, action = term.Search({CaseInSensitiveString=""}) })
    table.insert(config.keys, { key = "/", mods = "LEADER", action = term.Search({CaseInSensitiveString=""}) })

    table.insert(config.keys, {
      key = "l",
      mods = "LEADER",
      action = wezterm.action.QuickSelectArgs({
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
    table.insert(config.keys, { key = "PageUp", mods = "SHIFT", action = wezterm.action.ScrollToPrompt(-1) })
    table.insert(config.keys, { key = "PageDown", mods = "SHIFT", action = wezterm.action.ScrollToPrompt(1) })
    table.insert(config.keys, { key = "k", mods = mod, action = wezterm.action.ClearScrollback("ScrollbackOnly") })
    table.insert(config.keys, { key = "v", mods = "LEADER", action = wezterm.action.ActivateCopyMode })

    -- Clipboard
    table.insert(config.keys, { key = "c", mods = mod, action = wezterm.action.CopyTo("Clipboard") })
    table.insert(config.keys, { key = "v", mods = mod, action = wezterm.action.PasteFrom("Clipboard") })
    table.insert(config.keys, { key = "y", mods = "LEADER", action = wezterm.action.CopyTo("Clipboard") })
    table.insert(config.keys, { key = "p", mods = "LEADER", action = wezterm.action.PasteFrom("Clipboard") })
    table.insert(config.keys, { key = "Copy",  action = wezterm.action.CopyTo("Clipboard") })
    table.insert(config.keys, { key = "Paste", action = wezterm.action.PasteFrom("Clipboard") })
    table.insert(config.keys, { key = "Y", mods = "LEADER", action = wezterm.action.CopyTo("PrimarySelection") })
    table.insert(config.keys, { key = "P", mods = "LEADER", action = wezterm.action.PasteFrom("PrimarySelection") })
    table.insert(config.keys, { key = "Insert", mods = "CTRL", action = wezterm.action.CopyTo("PrimarySelection") })
    table.insert(config.keys, { key = "Insert", mods = "SHIFT", action = wezterm.action.PasteFrom("PrimarySelection") })

    -- Window Management
    table.insert(config.keys, { key = "n", mods = mod, action = wezterm.action.SpawnWindow })
    table.insert(config.keys, { key = "n", mods = "LEADER", action = wezterm.action.SpawnWindow })
    table.insert(config.keys, { key = "m", mods = mod, action = wezterm.action.Hide })
    table.insert(config.keys, { key = "h", mods = mod, action = wezterm.action.HideApplication })
    -- LEADER f reserved for file-manager module key table
    table.insert(config.keys, { key = "F", mods = "LEADER", action = wezterm.action.ToggleFullScreen })
    table.insert(config.keys, { key = "+", mods = mod, action = wezterm.action.IncreaseFontSize })
    table.insert(config.keys, { key = "-", mods = mod, action = wezterm.action.DecreaseFontSize })
    table.insert(config.keys, { key = "0", mods = mod, action = wezterm.action.ResetFontSize })

    -- Tab Management
    table.insert(config.keys, { key = "t", mods = mod, action = wezterm.action.SpawnTab("CurrentPaneDomain") })
    -- LEADER t reserved for domains module key table
    table.insert(config.keys, { key = "T", mods = "LEADER", action = wezterm.action.SpawnTab("DefaultDomain") })
    table.insert(config.keys, { key = "w", mods = mod, action = wezterm.action.CloseCurrentTab({ confirm = false }) })
    table.insert(config.keys, { key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) })
    table.insert(config.keys, { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(-1) })
    table.insert(config.keys, { key = "[", mods = mod, action = wezterm.action.ActivateTabRelative(-1) })
    table.insert(config.keys, { key = "]", mods = mod, action = wezterm.action.ActivateTabRelative(1) })
    table.insert(config.keys, { key = "{", mods = mod, action = wezterm.action.MoveTabRelative(-1) })
    table.insert(config.keys, { key = "}", mods = mod, action = wezterm.action.MoveTabRelative(1) })
    table.insert(config.keys, { key = "[", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) })
    table.insert(config.keys, { key = "]", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) })
    table.insert(config.keys, { key = "{", mods = "LEADER", action = wezterm.action.MoveTabRelative(-1) })
    table.insert(config.keys, { key = "}", mods = "LEADER", action = wezterm.action.MoveTabRelative(1) })
    table.insert(config.keys, { key = "PageUp", mods = "CTRL", action = wezterm.action.ActivateTabRelative(-1) })
    table.insert(config.keys, { key = "PageDown", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) })
    table.insert(config.keys, { key = "PageUp", mods = "CTRL|SHIFT", action = wezterm.action.MoveTabRelative(-1) })
    table.insert(config.keys, { key = "PageDown", mods = "CTRL|SHIFT", action = wezterm.action.MoveTabRelative(1) })

    for i = 1, 9 do
      table.insert(config.keys, { key = tostring(i), mods = mod, action = wezterm.action.ActivateTab(i) })
      table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = wezterm.action.ActivateTab(i) })
    end

    -- Pane Management
    table.insert(config.keys, { key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) })
    table.insert(config.keys, { key = "\\", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) })
    table.insert(config.keys, { key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState })
    table.insert(config.keys, { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = false }) })
    table.insert(config.keys, { key = "LeftArrow", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Left") })
    table.insert(config.keys, { key = "RightArrow", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Right") })
    table.insert(config.keys, { key = "UpArrow", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Up") })
    table.insert(config.keys, { key = "DownArrow", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Down") })
    table.insert(config.keys, { key = "LeftArrow", mods = "CTRL|SUPER", action = wezterm.action.AdjustPaneSize({ "Left", 2 }) })
    table.insert(config.keys, { key = "RightArrow", mods = "CTRL|SUPER", action = wezterm.action.AdjustPaneSize({ "Right", 2 }) })
    table.insert(config.keys, { key = "UpArrow", mods = "CTRL|SUPER", action = wezterm.action.AdjustPaneSize({ "Up", 2 }) })
    table.insert(config.keys, { key = "DownArrow", mods = "CTRL|SUPER", action = wezterm.action.AdjustPaneSize({ "Down", 2 }) })

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
  end,
}
