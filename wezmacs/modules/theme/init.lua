--[[
  Module: theme
  Category: ui
  Description: Color scheme selection and tab bar colors

  Provides:
  - Color scheme configuration (nil = use WezTerm default)
  - Tab bar color customization based on selected theme

  Configuration:
    color_scheme - WezTerm built-in color scheme name (nil = use WezTerm default)

  Examples:
    - "Horizon Dark (Gogh)"
    - "Tokyo Night"
    - "Catppuccin Mocha"
    - nil (uses WezTerm default)
]]

local wezterm = require("wezterm")
local spec = require("wezmacs.modules.theme.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  opts = opts or {}
  local mod = opts.color_scheme ~= nil and opts or wezmacs.get_module(M._NAME)

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
end

return M
