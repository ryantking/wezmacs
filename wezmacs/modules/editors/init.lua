--[[
  Module: editors
  Category: development
  Description: External code editor launchers (terminal editor and IDE)

  Provides:
  - Terminal editor in smart split (LEADER e t)
  - Terminal editor in new tab (LEADER e T)
  - IDE launcher in CWD (LEADER e i)
  - Configurable editor/IDE choices

  Configuration:
    terminal_editor - Terminal editor to use (default: "vim")
    ide - IDE to launch (default: "code" for VS Code)
    leader_key - Key to activate editors menu (default: "e")
    leader_mod - Modifier for leader key (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action
local actions = require("wezmacs.modules.editors.actions")

local M = {}

M._NAME = "editors"
M._CATEGORY = "development"
M._DESCRIPTION = "External code editor launchers"
M._EXTERNAL_DEPS = {}
M._CONFIG = {
  terminal_editor = "vim",
  ide = "code",
  leader_key = "e",
  leader_mod = "LEADER",
}

function M.apply_to_config(wezterm_config)
  local mod = wezmacs.get_module(M._NAME)

  -- Create editors key table
  wezterm_config.key_tables = wezterm_config.key_tables or {}
  wezterm_config.key_tables.editors = {
    {
      key = "t",
      action = wezterm.action_callback(function(window, pane)
        actions.terminal_editor_split(window, pane, mod.terminal_editor)
      end),
    },
    { key = "T", action = act.SpawnCommandInNewTab({ args = { mod.terminal_editor, "." } }) },
    {
      key = "i",
      action = wezterm.action_callback(function(window, pane)
        actions.launch_ide(window, pane, mod.ide)
      end),
    },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate editors menu
  wezterm_config.keys = wezterm_config.keys or {}
  table.insert(wezterm_config.keys, {
    key = mod.leader_key,
    mods = mod.leader_mod,
    action = act.ActivateKeyTable({
      name = "editors",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
