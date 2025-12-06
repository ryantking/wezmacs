--[[
  Module Spec: fonts
  Category: ui
  Description: Font configuration for terminal and UI elements
]]

return {
  name = "fonts",
  category = "ui",
  description = "Font configuration for terminal and UI elements",

  dependencies = {
    external = {},
    modules = {},
  },

  opts = {
    font = nil,
    font_size = nil,
    font_rules = {
      { intensity = "Normal", italic = false, weight = "Medium" },
      { intensity = "Bold", italic = false, weight = "ExtraBold" },
      { intensity = "Half", italic = false, weight = "Thin" },
      { intensity = "Normal", italic = true, weight = "Regular", style = "Italic" },
      { intensity = "Bold", italic = true, weight = "Bold", style = "Italic" },
      { intensity = "Half", italic = true, weight = "Thin", style = "Italic" },
    },
    ui_font = nil,
    ui_font_size = nil,
    ligatures = {
      enabled = false,
      harfbuzz_features = {
        "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08",
        "calt", "liga", "dlig",
      },
    },
  },

  keys = {},

  enabled = true,

  priority = 90,
}
