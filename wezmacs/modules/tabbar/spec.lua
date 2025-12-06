--[[
  Module Spec: tabbar
  Category: ui
  Description: Custom tab bar with process icons, zoom indicator, and decorative separators
]]

return {
  name = "tabbar",
  category = "ui",
  description = "Custom tab bar with process icons and decorative separators",

  dependencies = {
    external = {},
    modules = { "theme" },
  },

  opts = {
    arrow_solid = "",
    arrow_thin = "",
    use_fancy_tab_bar = true,
    tab_bar_at_bottom = false,
    hide_tab_bar_if_only_one_tab = true,
    tab_max_width = 60,
    unzoom_on_switch_pane = true,
  },

  keys = {},

  enabled = true,

  priority = 70,
}
