--[[
  Module: fonts
  Category: ui
  Description: Font configuration for terminal and UI elements
]]

local wezterm = require("wezterm")

return {
  name = "fonts",
  category = "ui",
  description = "Font configuration for terminal and UI elements",

  deps = {},

  opts = function()
    return {
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
    }
  end,

  keys = function()
    return {}
  end,

  enabled = true,

  priority = 90,

  setup = function(config, spec)
    local opts = spec.opts()
    
    -- Only apply font if configured
    if opts.font then
      config.font = wezterm.font_with_fallback({
        { family = opts.font, weight = "Medium" },
      })
      config.warn_about_missing_glyphs = false
    end

    -- Only apply font_size if configured
    if opts.font_size then
      config.font_size = opts.font_size
    end

    -- Apply ligatures only if ligatures feature is enabled
    if opts.ligatures and opts.ligatures.enabled then
      config.harfbuzz_features = opts.ligatures.harfbuzz_features
    end

    -- Font rules for different text styles
    if opts.font and opts.font_rules and type(opts.font_rules) == "table" and #opts.font_rules > 0 then
      config.font_rules = {}
      for _, rule_template in ipairs(opts.font_rules) do
        local rule = {
          intensity = rule_template.intensity,
          italic = rule_template.italic,
          font = wezterm.font_with_fallback({
            {
              family = opts.font,
              weight = rule_template.weight,
              style = rule_template.style,
            },
          }),
        }
        table.insert(config.font_rules, rule)
      end
    end

    -- UI fonts (for UI elements) - only if configured
    if opts.ui_font or opts.ui_font_size then
      if opts.ui_font then
        local ui_font = wezterm.font({ family = opts.ui_font })
        config.char_select_font = ui_font
        config.command_palette_font = ui_font

        -- Window frame styling
        if not config.window_frame then
          config.window_frame = {}
        end
        config.window_frame.font = ui_font
      end

      if opts.ui_font_size then
        config.char_select_font_size = opts.ui_font_size
        config.command_palette_font_size = opts.ui_font_size

        -- Window frame styling
        if not config.window_frame then
          config.window_frame = {}
        end
        config.window_frame.font_size = opts.ui_font_size
      end
    end
  end,
}
