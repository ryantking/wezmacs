--[[
  Module Spec: media
  Category: tools
  Description: Media player control with spotify_player
]]

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
      action = "actions.launch_spotify_player",
    },
  },

  enabled = function(ctx)
    return ctx.has_command("spotify_player")
  end,

  priority = 50,
}
