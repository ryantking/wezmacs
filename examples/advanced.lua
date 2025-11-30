--[[
  WezMacs Configuration: Advanced

  Advanced configuration showing:
  - Module selection with custom flags
  - Using overrides for fine-grained control
  - Custom module integration
  - Complex feature flags

  Copy this file to ~/.config/wezterm/user/config.lua to use it.
]]

local wezterm = require("wezterm")

return {
  -- Selective module loading
  modules = {
    ui = {
      "appearance",
      "tabbar",
      "window",
    },
    behavior = {
      "mouse",
    },
    editing = {
      "keybindings",
    },
    integration = {
      "plugins",
    },
    workflows = {
      "git",
      "workspace",
      "claude",
    },
    -- Enable custom modules
    custom = {
      -- Uncomment to enable custom modules:
      -- "my-custom-module",
    },
  },

  -- Fine-tuned flags
  flags = {
    ui = {
      -- Use different color scheme
      theme = "Nord",
      -- Use different font
      font = "JetBrains Mono",
      -- Larger font for better readability
      font_size = 18,
    },
    editing = {
      -- Customize leader key
      leader_key = "Space",
      leader_mod = "SUPER",  -- Use SUPER instead of CMD
    },
    workflows = {
      git = {
        leader_key = "g",
        leader_mod = "LEADER",
      },
      workspace = {
        leader_key = "w",
        leader_mod = "LEADER",
      },
      claude = {
        leader_key = "c",
        leader_mod = "LEADER",
      },
    },
  },

  -- Advanced customization via overrides
  overrides = function(config)
    -- Add custom event handler
    wezterm.on("window-focus-changed", function(window)
      if window:is_focused() then
        window:set_left_status("📍 Focused")
      else
        window:set_left_status("")
      end
    end)

    -- Add domain-specific keybindings
    config.keys = config.keys or {}

    -- Quick reload config
    table.insert(config.keys, {
      key = "r",
      mods = "CMD|CTRL",
      action = wezterm.action.ReloadConfiguration,
    })

    -- Custom pane split with logging
    table.insert(config.keys, {
      key = "b",
      mods = "LEADER",
      action = wezterm.action_callback(function(window, pane)
        window:toast_notification("WezMacs", "Custom split!", nil, 2000)
        pane:split({
          direction = "Right",
          size = 0.5,
        })
      end),
    })

    -- Customize scroll speed
    config.alternate_buffer_wheel_scroll_speed = 2

    -- Additional customizations
    config.window_padding = {
      left = 16,
      right = 16,
      top = 16,
      bottom = 16,
    }
  end,
}
