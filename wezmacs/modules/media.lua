--[[
  Module: media
  Category: tools
  Description: Media player control with spotify_player
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")

return {
  name = "media",
  category = "tools",
  description = "Media player control with spotify_player",

  deps = { "spotify_player" },

  opts = function()
    return {
      keybinding = "m",
      modifier = "LEADER",
    }
  end,

  keys = {
    LEADER = {
      m = {
        action = act.NewTab("spotify_player"),
        desc = "media/spotify-player",
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("spotify_player")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Apply keybindings
    keybindings.apply_keys(config, require("wezmacs.modules.media"), opts)
  end,
}
