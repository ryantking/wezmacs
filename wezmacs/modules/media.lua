--[[
  Module: media
  Category: tools
  Description: Media player control with spotify_player
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")

-- Define keys function (captured in closure for setup)
local function keys_fn()
  return {
    LEADER = {
      m = {
        action = act.NewTab("spotify_player"),
        desc = "media/spotify-player",
      },
    },
  }
end

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

  keys = keys_fn,

  enabled = function(ctx)
    return ctx.has_command("spotify_player")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Apply keybindings using the keys function (captured in closure)
    keybindings.apply_keys(config, {
      name = "media",
      keys = keys_fn,
    })
  end,
}
