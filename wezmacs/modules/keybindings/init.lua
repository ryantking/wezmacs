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
    table.insert(config.keys, { key = "r", mods = mod, action = act.ReloadConfiguration })
    table.insert(config.keys, { key = "r", mods = "LEADER", action = act.ReloadConfiguration })
    table.insert(config.keys, { key = "L", mods = "LEADER", action = act.ShowDebugOverlay })
    table.insert(config.keys, { key = "Enter", mods = "LEADER", action = act.ActivateCommandPalette })
    table.insert(config.keys, { key = "u", mods = "LEADER", action = act.CharSelect })
    table.insert(config.keys, { key = "Space", mods = "LEADER", action = act.QuickSelect })
    table.insert(config.keys, { key = "f", mods = mod, action = term.Search({CaseInSensitiveString=""}) })
    table.insert(config.keys, { key = "/", mods = "LEADER", action = term.Search({CaseInSensitiveString=""}) })

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
    table.insert(config.keys, { key = "k", mods = mod, action = act.ClearScrollback("ScrollbackOnly") })
    table.insert(config.keys, { key = "v", mods = "LEADER", action = act.ActivateCopyMode })

    -- Clipboard
    table.insert(config.keys, { key = "c", mods = mod, action = act.CopyTo("Clipboard") })
    table.insert(config.keys, { key = "v", mods = mod, action = act.PasteFrom("Clipboard") })
    table.insert(config.keys, { key = "y", mods = "LEADER", action = act.CopyTo("Clipboard") })
    table.insert(config.keys, { key = "p", mods = "LEADER", action = act.PasteFrom("Clipboard") })
    table.insert(config.keys, { key = "Copy",  action = act.CopyTo("Clipboard") })
    table.insert(config.keys, { key = "Paste", action = act.PasteFrom("Clipboard") })
    table.insert(config.keys, { key = "Y", mods = "LEADER", action = act.CopyTo("PrimarySelection") })
    table.insert(config.keys, { key = "P", mods = "LEADER", action = act.PasteFrom("PrimarySelection") })
    table.insert(config.keys, { key = "Insert", mods = "CTRL", action = act.CopyTo("PrimarySelection") })
    table.insert(config.keys, { key = "Insert", mods = "SHIFT", action = act.PasteFrom("PrimarySelection") })

    -- Window Management
    table.insert(config.keys, { key = "n", mods = mod, action = act.SpawnWindow })
    table.insert(config.keys, { key = "n", mods = "LEADER", action = act.SpawnWindow })
    table.insert(config.keys, { key = "m", mods = mod, action = act.Hide })
    table.insert(config.keys, { key = "h", mods = mod, action = act.HideApplication })
    -- LEADER f reserved for file-manager module key table
    table.insert(config.keys, { key = "F", mods = "LEADER", action = act.ToggleFullScreen })
    table.insert(config.keys, { key = "+", mods = mod, action = act.IncreaseFontSize })
    table.insert(config.keys, { key = "-", mods = mod, action = act.DecreaseFontSize })
    table.insert(config.keys, { key = "0", mods = mod, action = act.ResetFontSize })

    -- Tab Management
    table.insert(config.keys, { key = "t", mods = mod, action = act.SpawnTab("CurrentPaneDomain") })
    -- LEADER t reserved for domains module key table
    table.insert(config.keys, { key = "T", mods = "LEADER", action = act.SpawnTab("DefaultDomain") })
    table.insert(config.keys, { key = "w", mods = mod, action = act.CloseCurrentTab({ confirm = false }) })
    table.insert(config.keys, { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) })
    table.insert(config.keys, { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) })
    table.insert(config.keys, { key = "[", mods = mod, action = act.ActivateTabRelative(-1) })
    table.insert(config.keys, { key = "]", mods = mod, action = act.ActivateTabRelative(1) })
    table.insert(config.keys, { key = "{", mods = mod, action = act.MoveTabRelative(-1) })
    table.insert(config.keys, { key = "}", mods = mod, action = act.MoveTabRelative(1) })
    table.insert(config.keys, { key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) })
    table.insert(config.keys, { key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) })
    table.insert(config.keys, { key = "{", mods = "LEADER", action = act.MoveTabRelative(-1) })
    table.insert(config.keys, { key = "}", mods = "LEADER", action = act.MoveTabRelative(1) })
    table.insert(config.keys, { key = "PageUp", mods = "CTRL", action = act.ActivateTabRelative(-1) })
    table.insert(config.keys, { key = "PageDown", mods = "CTRL", action = act.ActivateTabRelative(1) })
    table.insert(config.keys, { key = "PageUp", mods = "CTRL|SHIFT", action = act.MoveTabRelative(-1) })
    table.insert(config.keys, { key = "PageDown", mods = "CTRL|SHIFT", action = act.MoveTabRelative(1) })

    for i = 1, 9 do
      table.insert(config.keys, { key = tostring(i), mods = mod, action = act.ActivateTab(i) })
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
  end,
}
