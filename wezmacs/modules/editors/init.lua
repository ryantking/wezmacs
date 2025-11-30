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
M._VERSION = "0.1.0"
M._DESCRIPTION = "External code editor launchers"
M._EXTERNAL_DEPS = { "helix (hx)", "cursor (optional)" }
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  terminal_editor = "vim",
  ide = "code",
  leader_key = "e",
  leader_mod = "LEADER",
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

function M.apply_to_config(wezterm_config, state)
  local split = require("wezmacs.utils.split")

  -- Terminal editor in smart split
  local function terminal_editor_split(window, pane)
    split.smart_split(pane, { state.config.terminal_editor, "." })
  end

  -- IDE launcher
  local function launch_ide(window, pane)
    local cwd_uri = pane:get_current_working_dir()
    local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
    wezterm.background_child_process({ state.config.ide, cwd })
  end

  -- Create editors key table
  wezterm_config.key_tables = wezterm_config.key_tables or {}
  wezterm_config.key_tables.editors = {
    { key = "t", action = wezterm.action_callback(terminal_editor_split) },
    { key = "T", action = act.SpawnCommandInNewTab({ args = { state.config.terminal_editor, "." } }) },
    { key = "i", action = wezterm.action_callback(launch_ide) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate editors menu
  wezterm_config.keys = wezterm_config.keys or {}
  table.insert(wezterm_config.keys, {
    key = state.config.leader_key,
    mods = state.config.leader_mod,
    action = act.ActivateKeyTable({
      name = "editors",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
