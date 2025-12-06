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

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.media.actions")
local spec = require("wezmacs.modules.media.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  -- Apply keybindings using library
  keybindings.apply_keys(config, spec, actions)
end

return M
