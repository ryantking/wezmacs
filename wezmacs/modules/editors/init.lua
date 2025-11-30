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
  wezterm_config.keys = wezterm_config.keys or {}

  -- Helix editor launcher
  table.insert(wezterm_config.keys, {
    key = state.config.helix_keybinding,
    mods = state.config.modifier,
    action = act.SpawnCommandInNewTab({ args = { "fish", "-c", "hx ." } })
  })

  -- Cursor editor launcher
  table.insert(wezterm_config.keys, {
    key = state.config.cursor_keybinding,
    mods = state.config.modifier,
    action = wezterm.action_callback(function(_, pane)
      local cwd_uri = pane:get_current_working_dir()
      local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
      wezterm.background_child_process({ "cursor", cwd })
    end)
  })
end

return M
