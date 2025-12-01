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
  terminal_editor = "vim",
  ide = "code",
  leader_key = "e",
  leader_mod = "LEADER",
}

function M.apply_to_config(wezterm_config)
  local mod = wezmacs.get_module(M._NAME)
  local split = require("wezmacs.utils.split")

  -- Terminal editor in smart split
  local function terminal_editor_split(window, pane)
    split.smart_split(pane, { mod.terminal_editor, "." })
  end

  -- IDE launcher
  local function launch_ide(window, pane)
    local cwd_uri = pane:get_current_working_dir()
    local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
    wezterm.background_child_process({ mod.ide, cwd })
  end

  -- Create editors key table
  wezterm_config.key_tables = wezterm_config.key_tables or {}
  wezterm_config.key_tables.editors = {
    { key = "t", action = wezterm.action_callback(terminal_editor_split) },
    { key = "T", action = act.SpawnCommandInNewTab({ args = { mod.terminal_editor, "." } }) },
    { key = "i", action = wezterm.action_callback(launch_ide) },
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
