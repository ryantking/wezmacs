--[[
  Module: tabbar
  Category: ui
  Description: Custom tab bar with process icons, zoom indicator, and decorative separators
]]

local wezterm = require("wezterm")
local titles = require("wezmacs.modules.tabbar.titles")

-- Module spec (LazyVim-style inline spec)
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

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.use_fancy_tab_bar ~= nil and opts or wezmacs.get_module("tabbar")

    config.use_fancy_tab_bar = mod.use_fancy_tab_bar
    config.tab_bar_at_bottom = mod.tab_bar_at_bottom
    config.hide_tab_bar_if_only_one_tab = mod.hide_tab_bar_if_only_one_tab
    config.tab_max_width = mod.tab_max_width
    config.unzoom_on_switch_pane = mod.unzoom_on_switch_pane

    wezterm.on("format-tab-title", function(tab, tabs, panes, config_obj, hover, max_width)
      local title = titles.format(tab, max_width)

      -- Check if tab_bar colors are available
      local colors = config_obj.resolved_palette
      if not colors.tab_bar then
        -- Return simple title without decorations if theme not loaded
        return { { Text = title } }
      end

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
      local arrow = (tab.is_active or is_last or next_is_active) and mod.arrow_solid or mod.arrow_thin
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
  end,
}
