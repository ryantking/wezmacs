--[[
  Module: tabs
  Description: Native tab bar with application context, zoom and unseen-output indicators
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

local hooks = require("wezmacs.modules.tabs.hooks")

return {
	name = "tabs",
	description = "Native tab bar with application context and pane indicators",

	opts = function()
		return {
			enable_tab_bar = true,
			use_fancy_tab_bar = true,
			tab_bar_at_bottom = false,
			hide_tab_bar_if_only_one_tab = false,
			show_new_tab_button_in_tab_bar = true,
			show_close_tab_button_in_tabs = false,
			tab_max_width = 32,
			unzoom_on_switch_pane = false,

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
			{
				key = "T",
				mods = opts.gui_shift_mod,
				action = act.SpawnTab("DefaultDomain"),
				desc = "new-default",
			},
			{
				key = "w",
				mods = opts.gui_mod,
				action = act.CloseCurrentTab({ confirm = false }),
				desc = "close",
			},
			{ key = "Tab", mods = opts.ctrl_mod, action = act.ActivateTabRelative(1), desc = "next" },
			{
				key = "Tab",
				mods = opts.ctrl_shift_mod,
				action = act.ActivateTabRelative(-1),
				desc = "prev",
			},
			{ key = "[", mods = opts.gui_mod, action = act.ActivateTabRelative(-1), desc = "prev" },
			{ key = "]", mods = opts.gui_mod, action = act.ActivateTabRelative(1), desc = "next" },
			{ key = "PageUp", mods = opts.ctrl_mod, action = act.ActivateTabRelative(-1), desc = "prev" },
			{
				key = "PageDown",
				mods = opts.ctrl_mod,
				action = act.ActivateTabRelative(1),
				desc = "next",
			},
			{
				key = "PageUp",
				mods = opts.ctrl_shift_mod,
				action = act.MoveTabRelative(-1),
				desc = "swap-prev",
			},
			{
				key = "PageDown",
				mods = opts.ctrl_shift_mod,
				action = act.MoveTabRelative(1),
				desc = "swap-next",
			},
		}

		-- Add numbered tab keys (1-9) with term modifier and gui modifier
		for i = 1, 9 do
			table.insert(keys_list, {
				key = tostring(i),
				mods = opts.term_mod,
				action = act.ActivateTab(i - 1),
				desc = "activate-" .. i,
			})
			table.insert(keys_list, {
				key = tostring(i),
				mods = opts.gui_mod,
				action = act.ActivateTab(i - 1),
				desc = "activate-" .. i,
			})
		end

		return keys_list
	end,

	setup = function(config, opts)
		config.enable_tab_bar = opts.enable_tab_bar
		config.show_new_tab_button_in_tab_bar = opts.show_new_tab_button_in_tab_bar
		config.show_close_tab_button_in_tabs = opts.show_close_tab_button_in_tabs
		config.use_fancy_tab_bar = opts.use_fancy_tab_bar
		config.tab_bar_at_bottom = opts.tab_bar_at_bottom
		config.hide_tab_bar_if_only_one_tab = opts.hide_tab_bar_if_only_one_tab
		config.tab_max_width = opts.tab_max_width
		config.unzoom_on_switch_pane = opts.unzoom_on_switch_pane

		wezterm.on("format-tab-title", hooks.format_tab_title)
	end,
}
