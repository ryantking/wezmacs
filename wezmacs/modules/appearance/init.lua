--[[
  Module: appearance
  Category: ui
  Description: Color scheme, fonts, visual styling, and font rules

  Provides:
  - Color scheme configuration (uses WezTerm default if not specified)
  - Font configuration with stylistic sets
  - Font rules for different text intensities and styles
  - UI font configuration for menus and window frame

  Configuration options:
    theme - Color scheme name (nil = use WezTerm default)
    font - Font family (nil = use WezTerm default)
    font_size - Terminal font size in points (nil = use WezTerm default)
    ui_font - UI elements font (nil = use WezTerm default)
    ui_font_size - UI elements font size (nil = use WezTerm default)
    window_decorations - Window decoration style (default: "RESIZE")

  Feature flags:
    ligatures - Enable font ligatures with configurable harfbuzz features
]]

local wezterm = require("wezterm")
local M = {}

M._NAME = "appearance"
M._CATEGORY = "ui"
M._DESCRIPTION = "Color scheme, fonts, visual styling"
M._EXTERNAL_DEPS = {}
M._FEATURES = {
  {
    name = "ligatures",
    config_schema = {
      harfbuzz_features = nil,
    },
    deps = {},
  },
}
M._CONFIG_SCHEMA = {
  theme = nil,
  font = nil,
  font_size = nil,
  ui_font = nil,
  ui_font_size = nil,
  window_decorations = "RESIZE",
}

function M.apply_to_config(config)
  local mod_config = wezmacs.get_config(M._NAME)
  local enabled_flags = wezmacs.get_enabled_flags(M._NAME)

  -- Only apply theme if configured
  if mod_config.theme then
    local theme = wezterm.get_builtin_color_schemes()[mod_config.theme]
    if not theme then
      wezterm.log_error("WezMacs: Color scheme '" .. mod_config.theme .. "' not found, using default")
      theme = wezterm.get_builtin_color_schemes()["Horizon Dark (Gogh)"]
    end

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
  end

  -- Only apply font if configured
  if mod_config.font then
    config.font = wezterm.font_with_fallback({
      { family = mod_config.font, weight = "Medium" },
    })
    config.warn_about_missing_glyphs = false
  end

  -- Only apply font_size if configured
  if mod_config.font_size then
    config.font_size = mod_config.font_size
  end

  -- Apply ligatures only if ligatures flag is enabled
  local enable_ligatures = false
  for _, flag in ipairs(enabled_flags) do
    if flag == "ligatures" then
      enable_ligatures = true
      break
    end
  end

  if enable_ligatures then
    local ligatures_config = mod_config.features and mod_config.features.ligatures
    if ligatures_config and ligatures_config.harfbuzz_features then
      config.harfbuzz_features = ligatures_config.harfbuzz_features
    else
      -- Default ligatures + stylistic sets
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
    end
  end

  -- Window decorations
  if mod_config.window_decorations then
    config.window_decorations = mod_config.window_decorations
  end

  -- Font rules for different text styles (only if font is configured)
  if mod_config.font then
    config.font_rules = {
      {
        intensity = "Normal",
        italic = false,
        font = wezterm.font_with_fallback({
          { family = mod_config.font, weight = "Medium" },
        }),
      },
      {
        intensity = "Bold",
        italic = false,
        font = wezterm.font_with_fallback({
          { family = mod_config.font, weight = "ExtraBold" },
        }),
      },
      {
        intensity = "Half",
        italic = false,
        font = wezterm.font_with_fallback({
          { family = mod_config.font, weight = "Thin" },
        }),
      },
      {
        intensity = "Normal",
        italic = true,
        font = wezterm.font_with_fallback({
          { family = mod_config.font, weight = "Regular", style = "Italic" },
        }),
      },
      {
        intensity = "Bold",
        italic = true,
        font = wezterm.font_with_fallback({
          { family = mod_config.font, weight = "Bold", style = "Italic" },
        }),
      },
      {
        intensity = "Half",
        italic = true,
        font = wezterm.font_with_fallback({
          { family = mod_config.font, weight = "Thin", style = "Italic" },
        }),
      },
    }
  end

  -- UI fonts (for UI elements) - only if configured
  if mod_config.ui_font or mod_config.ui_font_size then
    if mod_config.ui_font then
      local ui_font = wezterm.font({ family = mod_config.ui_font })
      config.char_select_font = ui_font
      config.command_palette_font = ui_font

      -- Window frame styling
      if not config.window_frame then
        config.window_frame = {}
      end
      config.window_frame.font = ui_font
    end

    if mod_config.ui_font_size then
      config.char_select_font_size = mod_config.ui_font_size
      config.command_palette_font_size = mod_config.ui_font_size

      -- Window frame styling
      if not config.window_frame then
        config.window_frame = {}
      end
      config.window_frame.font_size = mod_config.ui_font_size
    end
  end

  -- Apply theme-based UI styling if theme is configured
  if mod_config.theme then
    local theme = wezterm.get_builtin_color_schemes()[mod_config.theme]
    if theme then
      -- Window frame colors
      if not config.window_frame then
        config.window_frame = {}
      end
      config.window_frame.active_titlebar_bg = theme.background
      config.window_frame.inactive_titlebar_bg = theme.background
      config.window_frame.active_titlebar_fg = theme.foreground
      config.window_frame.inactive_titlebar_fg = theme.foreground

      -- Character selector appearance
      config.char_select_bg_color = theme.brights[1]
      config.char_select_fg_color = theme.foreground

      -- Command palette appearance
      config.command_palette_bg_color = theme.brights[1]
      config.command_palette_fg_color = theme.foreground
    end
  end
end

return M
