--[[
  Module: editors
  Category: development
  Description: External code editor launchers (Helix and Cursor)

  Provides:
  - Helix terminal editor launcher
  - Cursor GUI editor launcher
  - Open current directory in editor

  Configurable flags:
    helix_keybinding - Keybinding to launch Helix (default: "E")
    cursor_keybinding - Keybinding to launch Cursor (default: "C")
    modifier - Key modifier (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M._NAME = "editors"
M._CATEGORY = "development"
M._DESCRIPTION = "External code editor launchers"
M._EXTERNAL_DEPS = { "helix (hx)", "cursor (optional)" }
M._FEATURES = {}
M._CONFIG_SCHEMA = {
  terminal_editor = "vim",
  ide = "code",
  leader_key = "e",
  leader_mod = "LEADER",
}

function M.apply_to_config(wezterm_config)
  local mod_config = wezmacs.get_config(M._NAME)
  local split = require("wezmacs.utils.split")

  -- Terminal editor in smart split
  local function terminal_editor_split(window, pane)
    split.smart_split(pane, { mod_config.terminal_editor, "." })
  end

  -- IDE launcher
  local function launch_ide(window, pane)
    local cwd_uri = pane:get_current_working_dir()
    local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
    wezterm.background_child_process({ mod_config.ide, cwd })
  end

  -- Create editors key table
  wezterm_config.key_tables = wezterm_config.key_tables or {}
  wezterm_config.key_tables.editors = {
    { key = "t", action = wezterm.action_callback(terminal_editor_split) },
    { key = "T", action = act.SpawnCommandInNewTab({ args = { mod_config.terminal_editor, "." } }) },
    { key = "i", action = wezterm.action_callback(launch_ide) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate editors menu
  wezterm_config.keys = wezterm_config.keys or {}
  table.insert(wezterm_config.keys, {
    key = mod_config.leader_key,
    mods = mod_config.leader_mod,
    action = act.ActivateKeyTable({
      name = "editors",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
