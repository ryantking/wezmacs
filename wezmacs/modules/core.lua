--[[
  Module: core
  Category: system
  Description: Core WezTerm settings and global event handlers
]]

local wezterm = require("wezterm")

return {
  name = "core",
  category = "system",
  description = "Core WezTerm settings and global event handlers",

  deps = {},

  opts = function()
    return {
      enable_kitty_keyboard = false,
      enable_kitty_graphics = true,
      default_prog = nil,  -- nil = use WezTerm default
    }
  end,

  keys = function()
    return {}
  end,

  enabled = true,

  priority = 1000,  -- Highest priority, must load first

  setup = function(config, opts)
    -- Terminal protocol support
    config.enable_kitty_keyboard = opts.enable_kitty_keyboard
    config.enable_kitty_graphics = opts.enable_kitty_graphics

    -- Shell and workspace defaults
    if opts.default_prog then
      config.default_prog = opts.default_prog
    end

    -- Global event handlers
    wezterm.on("mux-is-process-stateful", function(_proc)
      return false
    end)
  end,
}
