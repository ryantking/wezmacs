--[[
  Module: theme
  Category: ui
  Description: Color scheme selection and tab bar colors
]]

local wezterm = require("wezterm")

-- Module spec (LazyVim-style inline spec)
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

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.color_scheme ~= nil and opts or wezmacs.get_module("theme")

    -- Only apply theme if configured
    if mod.color_scheme then
      local theme = wezterm.get_builtin_color_schemes()[mod.color_scheme]
      if not theme then
        wezterm.log_error("WezMacs: Color scheme '" .. mod.color_scheme .. "' not found, using default")
        -- Don't apply anything, let WezTerm use its default
        return
      end

      -- Apply color scheme
      config.colors = theme

      -- Customize tab bar colors based on theme
      config.colors.tab_bar = {
        background = theme.background,
        inactive_tab_edge = theme.ansi[8],
        inactive_tab_edge_hover = theme.foreground,

        active_tab = {
          bg_color = theme.background,
          fg_color = theme.ansi[5],
          intensity = "Bold",
        },

        inactive_tab = {
          bg_color = theme.background,
          fg_color = theme.ansi[8],
          intensity = "Half",
        },

        inactive_tab_hover = {
          bg_color = theme.brights[1],
          fg_color = theme.ansi[8],
        },

        new_tab = {
          bg_color = theme.background,
          fg_color = theme.ansi[8],
        },

        new_tab_hover = {
          bg_color = theme.brights[1],
          fg_color = theme.ansi[8],
        },
      }
    end
  end,
}
