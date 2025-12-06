--[[
  Module: media
  Category: tools
  Description: Media player control with spotify_player
]]

local act = require("wezmacs.action")

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

  enabled = true,

  priority = 50,

  setup = function(config, opts)
    -- Module-specific setup (if any)
  end,
}
