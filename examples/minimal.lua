--[[
  WezMacs Configuration: Minimal

  A minimal configuration with just the essentials:
  - appearance: Colors and fonts
  - keybindings: Pane and tab navigation

  Copy this file to ~/.config/wezterm/user/config.lua to use it.
]]

return {
  modules = {
    ui = {
      "appearance",  -- Colors, fonts, visual styling
    },
    editing = {
      "keybindings",  -- Pane/tab management, navigation
    },
  },

  -- Optional: customize appearance
  flags = {
    ui = {
      theme = "Horizon Dark (Gogh)",
      font = "Iosevka Mono",
      font_size = 16,
    },
  },
}
