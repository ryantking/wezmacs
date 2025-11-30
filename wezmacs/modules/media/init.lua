--[[
  Module: media
  Category: tools
  Description: Media player control with spotify_player

  Provides:
  - spotify_player launcher in new tab
  - Spotify playback control from terminal

  Configurable flags:
    keybinding - Keybinding to launch spotify_player (default: "m")
    modifier - Key modifier (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M._NAME = "media"
M._CATEGORY = "tools"
M._DESCRIPTION = "Media player control with spotify_player"
M._EXTERNAL_DEPS = { "spotify_player" }
M._FEATURES = {}
M._CONFIG_SCHEMA = {
  keybinding = "m",
  modifier = "LEADER",
}

function M.apply_to_config(wezterm_config, state)
  wezterm_config.keys = wezterm_config.keys or {}

  table.insert(wezterm_config.keys, {
    key = state.config.keybinding,
    mods = state.config.modifier,
    action = act.SpawnCommandInNewTab({ args = { "spotify_player" } })
  })
end

return M
