--[[
  Module: app
  Description: Application launchers and integrations (docker, kubernetes, media, system monitor)
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
  name = "app",
  description = "Application launchers (docker, kubernetes, media, system monitor)",

  deps = { "lazydocker", "k9s", "spotify_player", "btm" },

  opts = function()
    return {
      audible_bell = "Disabled",
      disable_default_key_bindings = true,
      leader_key = "Space",
      leader_mod = wezmacs.config.platform == "darwin" and wezmacs.config.gui_mod
        or wezmacs.config.ctrl_mod,

      -- Keybindings
      term_mod = wezmacs.config.term_mod,
      gui_mod = wezmacs.config.gui_mod,
    }
  end,

  keys = function(opts)
    return {
      { key = "q", mods = opts.gui_mod, action = act.QuitApplication, desc = "quit" },
      { key = "h", mods = opts.gui_mod, action = act.HideApplication, desc = "hide" },
      { key = "r", mods = opts.term_mod, action = act.ReloadConfiguration, desc = "reload" },
      { key = "r", mods = opts.gui_mod, action = act.ReloadConfiguration, desc = "reload" },
      { key = "l", mods = opts.term_mod, action = act.ShowDebugOverlay, desc = "debug" },
      { key = "p", mods = opts.term_mod, action = act.ActivateCommandPalette, desc = "commands" },
      { key = "?", mods = "LEADER", action = act.ActivateCommandPalette, desc = "commands" },
      { key = "u", mods = opts.term_mod, action = act.CharSelect, desc = "insert-char" },

      LEADER = {
        [","] = {
          {
            key = "d",
            action = wezmacs.action.SmartSplit("lazydocker"),
            desc = "lazydocker/split",
          },
          { key = "D", action = wezmacs.action.NewTab("lazydocker"), desc = "lazydocker/tab" },
          { key = "k", action = wezmacs.action.SmartSplit("k9s"), desc = "kubernetes" },
          { key = "K", action = wezmacs.action.NewTab("k9s"), desc = "kubernetes" },
          { key = "s", action = wezmacs.action.SmartSplit("spotify_player"), desc = "spotify" },
          { key = "S", action = wezmacs.action.NewTab("spotify_player"), desc = "spotify" },
          { key = "m", action = wezmacs.action.SmartSplit("btm"), desc = "monitor" },
          { key = "M", action = wezmacs.action.NewTab("btm"), desc = "monitor" },
        },
      },
    }
  end,

  setup = function(config, opts)
    config.audible_bell = opts.audible_bell
    config.disable_default_key_bindings = opts.disable_default_key_bindings

    config.leader = {
      key = opts.leader_key,
      mods = opts.leader_mod,
      timeout_milliseconds = 5000,
    }
  end,
}
