--[[
  Module Spec: window
  Category: ui
  Description: Window decorations, padding, scrolling, and cursor behavior
]]

return {
  name = "window",
  category = "ui",
  description = "Window behavior, padding, and cursor settings",

  dependencies = {
    external = {},
    modules = { "theme" },
  },

  opts = {
    padding = 16,
    scrollback_lines = 5000,
    decorations = "RESIZE",
  },

  keys = {},

  enabled = true,

  priority = 80,
}
