--[[
  Module: media
  Category: tools
  Description: Media player control with spotify_player
]]

local keybindings = require("wezmacs.lib.keybindings")
local action_lib = require("wezmacs.lib.actions")

-- Actions (inline)
local actions = {
  launch_spotify_player = action_lib.new_tab_action("spotify_player"),
}

-- Module spec (LazyVim-style inline spec)
return {
  name = "media",
  category = "tools",
  description = "Media player control with spotify_player",

  dependencies = {
    external = { "spotify_player" },
    modules = { "keybindings" },
  },

  opts = {
    keybinding = "m",
    modifier = "LEADER",
  },

  keys = {
    {
      key = "m",
      mods = "LEADER",
      action = actions.launch_spotify_player,
    },
  },

  enabled = function(ctx)
    return ctx.has_command("spotify_player")
  end,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    -- Get spec (self-reference via closure)
    local spec = require("wezmacs.modules.media")
    -- Apply keybindings using library
    keybindings.apply_keys(config, spec)
  end,
}
