--[[
  Module Spec: core
  Category: system
  Description: Core WezTerm settings and global event handlers
]]

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
}
