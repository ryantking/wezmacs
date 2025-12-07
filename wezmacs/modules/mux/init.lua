--[[
  Module: mux
  Description: Domain management and workspace switching
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local quick_domains = wezterm.plugin.require("https://github.com/DavidRR-F/quick_domains.wezterm")

return {
	name = "mux",
	description = "Domain management and workspace switching",

	deps = { "zoxide" },

	opts = {
		default_workspace = "~",

		-- Keybindings
		term_mod = wezmacs.config.term_mod,
		term_alt_mod = wezmacs.config.term_mod .. "|ALT",
		gui_mod = wezmacs.config.gui_mod,
		ctrl_mod = wezmacs.config.ctrl_mod,

		-- Quick Domains Plugin
		quick_domains = {
			keys = {
				attach = { key = "d", mods = "LEADER", tbl = "" },
				vsplit = { key = "|", mods = "LEADER", tbl = "" },
				hsplit = { key = "_", mods = "LEADER", tbl = "" },
			},
			auto = {
				ssh_ignore = true,
				exec_ignore = {
					ssh = true,
					docker = true,
					kubernetes = true,
				},
			},
		},
	},

	keys = function(opts)
		return {
			-- Pane Management
			{
				key = '"',
				mods = opts.term_alt_mod,
				action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
				desc = "split-vertical",
			},
			{
				key = "-",
				mods = "LEADER",
				action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
				desc = "split-vertical",
			},
			{
				key = "\\",
				mods = "LEADER",
				action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
				desc = "split-horizontal",
			},
			{
				key = "X",
				mods = "LEADER|SHIFT",
				action = act.CloseCurrentPane({ confirm = false }),
				desc = "close-pane",
			},
			{
				key = "z",
				mods = opts.term_mod,
				action = act.TogglePaneZoomState,
				desc = "zoom-pane",
			},
			{
				key = "z",
				mods = "LEADER",
				action = act.TogglePaneZoomState,
				desc = "zoom-pane",
			},
			{
				key = "N",
				mods = "LEADER",
				action = wezterm.action_callback(function(_, pane)
					pane:move_to_new_tab()
				end),
				desc = "wezterm/move-pane-to-tab",
			},
			{
				key = "W",
				mods = "LEADER",
				action = wezterm.action_callback(function(_, pane)
					pane:move_to_new_window()
				end),
				desc = "wezterm/move-pane-to-window",
			},
			{
				key = "LeftArrow",
				mods = opts.term_mod,
				action = act.ActivatePaneDirection("Left"),
				desc = "pane-left",
			},
			{
				key = "RightArrow",
				mods = opts.term_mod,
				action = act.ActivatePaneDirection("Right"),
				desc = "pane-right",
			},
			{
				key = "UpArrow",
				mods = opts.term_mod,
				action = act.ActivatePaneDirection("Up"),
				desc = "pane-up",
			},
			{
				key = "DownArrow",
				mods = opts.term_mod,
				action = act.ActivatePaneDirection("Down"),
				desc = "pane-down",
			},
			{
				key = "LeftArrow",
				mods = opts.term_alt_mod,
				action = act.AdjustPaneSize({ "Left", 2 }),
				desc = "pane-resize-left",
			},
			{
				key = "RightArrow",
				mods = opts.term_alt_mod,
				action = act.AdjustPaneSize({ "Right", 2 }),
				desc = "pane-resize-right",
			},
			{
				key = "UpArrow",
				mods = opts.term_alt_mod,
				action = act.AdjustPaneSize({ "Up", 2 }),
				desc = "pane-resize-up",
			},
			{
				key = "DownArrow",
				mods = opts.term_alt_mod,
				action = act.AdjustPaneSize({ "Down", 2 }),
				desc = "pane-resize-down",
			},

			-- Workspace Switcher
			{
				key = "s",
				mods = "LEADER",
				action = workspace_switcher.switch_workspace(),
				desc = "workspace-switch",
			},
			{
				key = "S",
				mods = "LEADER",
				action = workspace_switcher.switch_to_prev_workspace(),
				desc = "workspace-switch-prev",
			},
		}
	end,

	setup = function(config, opts)
		config.default_workspace = opts.default_workspace
		quick_domains.apply_to_config(config, opts.quick_domains)
	end,
}
