--[[
  Module: core
  Category: system
  Description: Core WezTerm settings and global event handlers
]]

local wezterm = require("wezterm")

-- Module spec (LazyVim-style inline spec)
return {
  name = "core",
  category = "system",
  description = "Core WezTerm settings and global event handlers",

  dependencies = {
    external = {},
    modules = {},
  },

  opts = {
    enable_kitty_keyboard = false,
    enable_kitty_graphics = true,
    default_prog = nil,  -- nil = use WezTerm default
  },

  keys = {},

  enabled = true,

  priority = 1000,  -- Highest priority, must load first

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.default_prog ~= nil and opts or wezmacs.get_module("core")

    -- Terminal protocol support
    config.enable_kitty_keyboard = mod.enable_kitty_keyboard
    config.enable_kitty_graphics = mod.enable_kitty_graphics

    -- Shell and workspace defaults
    if mod.default_prog then
      config.default_prog = mod.default_prog
    end

    -- Global event handlers
    wezterm.on("mux-is-process-stateful", function(_proc)
      return false
    end)
  end,
}
