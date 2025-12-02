--[[
  Module: tabbar
  Category: ui
  Description: Custom tab bar with process icons, zoom indicator, and decorative separators

  Provides:
  - Process-specific nerd font icons (25+ applications)
  - Zoom state indicator in tab title
  - Decorative arrow separators between tabs
  - Dynamic working directory fallback for editors
  - Auto-hide tab bar when only one tab

  Configurable flags:
    none currently
]]

local wezterm = require("wezterm")
local titles = require("wezmacs.modules.tabbar.titles")

local M = {}

M._NAME = "tabbar"
M._CATEGORY = "ui"
M._DESCRIPTION = "Custom tab bar with process icons and decorative separators"
M._EXTERNAL_DEPS = {}
M._CONFIG = {}

M.arrow_solid = ""
M.arrow_thin = ""

function M.apply_to_config(config)
  config.use_fancy_tab_bar = true
  config.tab_bar_at_bottom = false
  config.hide_tab_bar_if_only_one_tab = true
  config.tab_max_width = 60
  config.unzoom_on_switch_pane = true

  wezterm.on("format-tab-title", function(tab, tabs, panes, config_obj, hover, max_width)
    local title = M.title(tab, max_width)
    local colors = config_obj.resolved_palette
    local active_bg = colors.tab_bar.active_tab.bg_color
    local inactive_bg = colors.tab_bar.inactive_tab.bg_color

    local tab_idx = 1
    for i, t in ipairs(tabs) do
      if t.tab_id == tab.tab_id then
        tab_idx = i
        break
      end
    end
    local is_last = tab_idx == #tabs
    local next_tab = tabs[tab_idx + 1]
    local next_is_active = next_tab and next_tab.is_active
    local arrow = (tab.is_active or is_last or next_is_active) and M.arrow_solid or M.arrow_thin
    local arrow_bg = inactive_bg
    local arrow_fg = colors.tab_bar.inactive_tab_edge

    if is_last then
      arrow_fg = tab.is_active and active_bg or inactive_bg
      arrow_bg = colors.tab_bar.background
    elseif tab.is_active then
      arrow_bg = inactive_bg
      arrow_fg = active_bg
    elseif next_is_active then
      arrow_bg = active_bg
      arrow_fg = inactive_bg
    end

    local ret = tab.is_active and {
      { Attribute = { Intensity = "Bold" } },
      { Attribute = { Italic = true } },
    } or {}
    ret[#ret + 1] = { Text = title }
    ret[#ret + 1] = { Foreground = { Color = arrow_fg } }
    ret[#ret + 1] = { Background = { Color = arrow_bg } }
    ret[#ret + 1] = { Text = arrow }
    return ret
  end)
end

return M
