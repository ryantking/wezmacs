--[[
  Module: appearance
  Category: ui
  Description: Color scheme, fonts, visual styling, and font rules

  Provides:
  - Horizon Dark Gogh color scheme
  - Iosevka Mono with extensive stylistic sets
  - Font rules for different text intensities and styles
  - UI font configuration

  Configurable flags:
    theme - Color scheme name (default: "Horizon Dark (Gogh)")
    font - Font family (default: "Iosevka Mono")
    font_size - Terminal font size in points (default: 16)
]]

local wezterm = require("wezterm")
local M = {}

M._NAME = "appearance"
M._CATEGORY = "ui"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Color scheme, fonts, visual styling"
M._EXTERNAL_DEPS = {}
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  theme = "Horizon Dark (Gogh)",
  font = "Iosevka Mono",
  font_size = 16,
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

function M.apply_to_config(config, state)
  -- Get builtin color scheme
  local theme = wezterm.get_builtin_color_schemes()[state.config.theme]
  if not theme then
    wezterm.log_error("WezMacs: Color scheme '" .. state.config.theme .. "' not found, using default")
    theme = wezterm.get_builtin_color_schemes()["Horizon Dark (Gogh)"]
  end

  -- Font configuration
  config.font = wezterm.font_with_fallback({
    { family = state.config.font, weight = "Medium" },
  })
  config.font_size = state.config.font_size
  config.warn_about_missing_glyphs = false

  -- Font features: ligatures + stylistic sets
  config.harfbuzz_features = {
    "ss01", -- Contextual alternatives
    "ss02", -- Stylistic Set 2
    "ss03", -- Stylistic Set 3
    "ss04", -- Stylistic Set 4
    "ss05", -- Stylistic Set 5
    "ss06", -- Stylistic Set 6
    "ss07", -- Stylistic Set 7
    "ss08", -- Stylistic Set 8
    "calt", -- Contextual alternates
    "liga", -- Standard ligatures
    "dlig", -- Discretionary ligatures
  }

  -- Font rules for different text styles
  config.font_rules = {
    {
      intensity = "Normal",
      italic = false,
      font = wezterm.font_with_fallback({
        { family = state.config.font, weight = "Medium" },
      }),
    },
    {
      intensity = "Bold",
      italic = false,
      font = wezterm.font_with_fallback({
        { family = state.config.font, weight = "ExtraBold" },
      }),
    },
    {
      intensity = "Half",
      italic = false,
      font = wezterm.font_with_fallback({
        { family = state.config.font, weight = "Thin" },
      }),
    },
    {
      intensity = "Normal",
      italic = true,
      font = wezterm.font_with_fallback({
        { family = state.config.font, weight = "Regular", style = "Italic" },
      }),
    },
    {
      intensity = "Bold",
      italic = true,
      font = wezterm.font_with_fallback({
        { family = state.config.font, weight = "Bold", style = "Italic" },
      }),
    },
    {
      intensity = "Half",
      italic = true,
      font = wezterm.font_with_fallback({
        { family = state.config.font, weight = "Thin", style = "Italic" },
      }),
    },
  }

  -- Apply color scheme
  config.colors = theme

  -- Customize tab bar colors
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

  -- UI fonts (for UI elements)
  local ui_font = wezterm.font({ family = "Iosevka" })
  local ui_font_size = 14

  -- Window frame styling
  config.window_frame = {
    font = ui_font,
    font_size = ui_font_size,
    active_titlebar_bg = theme.background,
    inactive_titlebar_bg = theme.background,
    active_titlebar_fg = theme.foreground,
    inactive_titlebar_fg = theme.foreground,
  }

  -- Character selector appearance
  config.char_select_bg_color = theme.brights[1]
  config.char_select_fg_color = theme.foreground
  config.char_select_font = ui_font
  config.char_select_font_size = ui_font_size

  -- Command palette appearance
  config.command_palette_bg_color = theme.brights[1]
  config.command_palette_fg_color = theme.foreground
  config.command_palette_font = ui_font
  config.command_palette_font_size = ui_font_size
end

return M
