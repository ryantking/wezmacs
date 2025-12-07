--[[
  Module: tabs
  Description: Custom tab bar with process icons, zoom indicator, and decorative separators
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

-- Use local path for module-specific code
local titles = require("titles")

return {
	name = "tabs",
	description = "Custom tab bar with process icons and decorative separators",

	opts = function()
		return {
			arrow_solid = "",
			arrow_thin = "",
			use_fancy_tab_bar = true,
			tab_bar_at_bottom = false,
			hide_tab_bar_if_only_one_tab = true,
			tab_max_width = 60,
			unzoom_on_switch_pane = true,
			font = nil,
			font_size = nil,

			-- Keybindings
			term_mod = wezmacs.config.term_mod,
			gui_mod = wezmacs.config.gui_mod,
			gui_shift_mod = wezmacs.config.gui_mod .. "|SHIFT",
			ctrl_mod = wezmacs.config.ctrl_mod,
			ctrl_shift_mod = wezmacs.config.ctrl_mod .. "|SHIFT",
		}
	end,

	keys = function(opts)
		local keys_list = {
			-- Tab Management
			{ key = "t", mods = opts.term_mod, action = act.SpawnTab("CurrentPaneDomain"), desc = "new" },
			{ key = "t", mods = opts.gui_mod, action = act.SpawnTab("CurrentPaneDomain"), desc = "new" },
			{ key = "T", mods = opts.gui_shift_mod, action = act.SpawnTab("DefaultDomain"), desc = "new-default" },
			{ key = "w", mods = opts.gui_mod, action = act.CloseCurrentTab({ confirm = false }), desc = "close" },
			{ key = "Tab", mods = opts.ctrl_mod, action = act.ActivateTabRelative(1), desc = "next" },
			{ key = "Tab", mods = opts.ctrl_shift_mod, action = act.ActivateTabRelative(-1), desc = "prev" },
			{ key = "[", mods = opts.gui_shift_mod, action = act.ActivateTabRelative(-1), desc = "next" },
			{ key = "]", mods = opts.gui_shift_mod, action = act.ActivateTabRelative(1), desc = "prev" },
			{ key = "PageUp", mods = opts.ctrl_mod, action = act.ActivateTabRelative(1), desc = "next" },
			{ key = "PageDown", mods = opts.ctrl_mod, action = act.ActivateTabRelative(-1), desc = "prev" },
			{ key = "PageUp", mods = opts.ctrl_shift_mod, action = act.MoveTabRelative(-1), desc = "swap-next" },
			{ key = "PageDown", mods = opts.ctrl_shift_mod, action = act.MoveTabRelative(1), desc = "swap-prev" },
		}

		-- Add numbered tab keys (1-9) with term modifier and gui modifier
		for i = 1, 9 do
			table.insert(
				keys_list,
				{ key = tostring(i), mods = opts.term_mod, action = act.ActivateTab(i), desc = "activate-" .. i }
			)
			table.insert(
				keys_list,
				{ key = tostring(i), mods = opts.gui_mod, action = act.ActivateTab(i), desc = "activate-" .. i }
			)
		end

		return keys_list
	end,

	setup = function(config, opts)
		config.use_fancy_tab_bar = opts.use_fancy_tab_bar
		config.tab_bar_at_bottom = opts.tab_bar_at_bottom
		config.hide_tab_bar_if_only_one_tab = opts.hide_tab_bar_if_only_one_tab
		config.tab_max_width = opts.tab_max_width
		config.unzoom_on_switch_pane = opts.unzoom_on_switch_pane

		-- Tab bar colors based on color scheme
		local color_scheme = wezmacs.color_scheme()
		if color_scheme then
			-- Ensure colors.tab_bar exists
			if not config.colors then
				config.colors = {}
			end
			if not config.colors.tab_bar then
				config.colors.tab_bar = {}
			end

			-- Customize tab bar colors based on theme
			config.colors.tab_bar.background = color_scheme.background
			config.colors.tab_bar.inactive_tab_edge = color_scheme.ansi[8]
			config.colors.tab_bar.inactive_tab_edge_hover = color_scheme.foreground

			config.colors.tab_bar.active_tab = {
				bg_color = color_scheme.background,
				fg_color = color_scheme.ansi[5],
				intensity = "Bold",
			}

			config.colors.tab_bar.inactive_tab = {
				bg_color = color_scheme.background,
				fg_color = color_scheme.ansi[8],
				intensity = "Half",
			}

			config.colors.tab_bar.inactive_tab_hover = {
				bg_color = color_scheme.brights[1],
				fg_color = color_scheme.ansi[8],
			}

			config.colors.tab_bar.new_tab = {
				bg_color = color_scheme.background,
				fg_color = color_scheme.ansi[8],
			}

			config.colors.tab_bar.new_tab_hover = {
				bg_color = color_scheme.brights[1],
				fg_color = color_scheme.ansi[8],
			}
		end

		-- UI fonts (for UI elements) - only if configured
		if opts.font or opts.font_size then
			if opts.font then
				local ui_font = wezterm.font({ family = opts.font })
				config.char_select_font = ui_font
				config.command_palette_font = ui_font

				-- Window frame styling
				if not config.window_frame then
					config.window_frame = {}
				end
				config.window_frame.font = ui_font
			end

			if opts.font_size then
				config.char_select_font_size = opts.font_size
				config.command_palette_font_size = opts.font_size

				-- Window frame styling
				if not config.window_frame then
					config.window_frame = {}
				end
				config.window_frame.font_size = opts.font_size
			end
		end

		wezterm.on("format-tab-title", function(tab, tabs, panes, config_obj, _, max_width)
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
			local arrow = (tab.is_active or is_last or next_is_active) and opts.arrow_solid or opts.arrow_thin
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

			local ret = tab.is_active
					and {
						{ Attribute = { Intensity = "Bold" } },
						{ Attribute = { Italic = true } },
					}
				or {}
			ret[#ret + 1] = { Text = title }
			ret[#ret + 1] = { Foreground = { Color = arrow_fg } }
			ret[#ret + 1] = { Background = { Color = arrow_bg } }
			ret[#ret + 1] = { Text = arrow }
			return ret
		end)
	end,
}
