--[[
  Module: fonts
  Category: ui
  Description: Font configuration for terminal and UI elements

  Provides:
  - Terminal font configuration (family and size)
  - Font rules for different text styles (bold, italic, etc.)
  - Font ligatures with configurable harfbuzz features
  - UI element fonts (char_select, command_palette, window_frame)

  Configuration options:
    font - Terminal font family (nil = use WezTerm default)
    font_size - Terminal font size in points (nil = use WezTerm default)
    font_rules - Font rules for text styles:
      - nil = auto-generate rules if font is set (backward compat)
      - {} = disable font rules entirely
      - [...] = custom rules array
    ui_font - UI elements font (nil = use WezTerm default)
    ui_font_size - UI elements font size (nil = use WezTerm default)

  Feature flags:
    ligatures - Enable font ligatures with configurable harfbuzz features
]]

local wezterm = require("wezterm")
local M = {}

M._NAME = "fonts"
M._CATEGORY = "ui"
M._DESCRIPTION = "Font configuration for terminal and UI elements"
M._EXTERNAL_DEPS = {}
M._CONFIG = {
  font = nil,
  font_size = nil,
  font_rules = nil,
  ui_font = nil,
  ui_font_size = nil,
  ligatures = {
    enabled = false,
    config = {
      harfbuzz_features = nil,  -- nil = use default ligatures
    },
  },
}

function M.apply_to_config(config)
  local mod = wezmacs.get_module(M._NAME)

  -- Only apply font if configured
  if mod.font then
    config.font = wezterm.font_with_fallback({
      { family = mod.font, weight = "Medium" },
    })
    config.warn_about_missing_glyphs = false
  end

  -- Only apply font_size if configured
  if mod.font_size then
    config.font_size = mod.font_size
  end

  -- Apply ligatures only if ligatures feature is enabled
  if mod.ligatures and mod.ligatures.enabled then
    local ligatures_config = mod.ligatures.config
    if ligatures_config.harfbuzz_features then
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

  -- Font rules for different text styles
  -- nil = auto-generate if font is set, {} = disable, [...] = custom
  if mod_config.font_rules ~= nil then
    -- User explicitly set font_rules (empty or custom)
    if type(mod_config.font_rules) == "table" and #mod_config.font_rules > 0 then
      config.font_rules = mod_config.font_rules
    end
    -- else: font_rules = {} means disable, don't set anything
  elseif mod_config.font then
    -- Auto-generate font rules if font is configured and font_rules is nil
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
end

return M
