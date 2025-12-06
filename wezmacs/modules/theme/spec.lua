--[[
  Module Spec: theme
  Category: ui
  Description: Color scheme selection and tab bar colors
]]

return {
  name = "theme",
  category = "ui",
  description = "Color scheme selection and tab bar colors",

  dependencies = {
    external = {},
    modules = {},
  },

  opts = {
    color_scheme = nil,  -- nil = use WezTerm default
  },

  keys = {},

  enabled = true,

  priority = 100,  -- High priority, loads early
}
