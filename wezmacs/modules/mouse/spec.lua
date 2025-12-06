--[[
  Module Spec: mouse
  Category: behavior
  Description: Mouse bindings and behavior
]]

return {
  name = "mouse",
  category = "behavior",
  description = "Mouse bindings and behavior",

  dependencies = {
    external = {},
    modules = {},
  },

  opts = {
    leader_mod = "CMD",
  },

  keys = {},

  enabled = true,

  priority = 50,
}
