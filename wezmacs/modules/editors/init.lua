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

local M = {}

M._NAME = "editors"
M._CATEGORY = "development"
M._DESCRIPTION = "External code editor launchers"
M._EXTERNAL_DEPS = {}
M._CONFIG = {
  editor = "vim",
  ide = "code",
  editor_split_key = "e",
  editor_tab_key = "E",
  ide_key = "i",
}

function M.apply_to_config(wezterm_config)
  local mod = wezmacs.get_module(M._NAME)
  local actions = require("wezmacs.modules.editors.actions").setup(mod.editor, mod.ide)

  wezterm_config.keys = wezterm_config.keys or {}
  table.insert(
    wezterm_config.keys,
    { key = mod.editor_split_key, mods = "LEADER", action = wezterm.action_callback(actions.terminal_smart_split) }
  )
  table.insert(
    wezterm_config.keys,
    {
      key = mod.editor_tab_key,
      mods = "LEADER",
      action = act.SpawnCommandInNewTab({args = { os.getenv("SHELL") or "/bin/bash", "-lc", mod.editor }})
    }
  )
  table.insert(
    wezterm_config.keys,
    { key = mod.ide_key, mods = "LEADER", action = wezterm.action_callback(actions.launch_ide) }
  )
end

return M
