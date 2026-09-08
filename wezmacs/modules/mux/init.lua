--[[
  Module: mux
  Description: Domain management and workspace switching
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

local workspaces = require("wezmacs.modules.mux.workspaces")
local hosts = require("wezmacs.modules.mux.hosts")

local function focus_gui(gui)
	gui:focus()
	if wezterm.target_triple:find("apple-darwin", 1, true) then
		-- Activate this helper's parent GUI, never another WezTerm instance.
		wezterm.run_child_process({
			"/usr/bin/osascript",
			"-l",
			"JavaScript",
			"-e",
			'ObjC.import("AppKit"); ObjC.bindFunction("getppid", ["int", []]); '
				.. "$.NSRunningApplication.runningApplicationWithProcessIdentifier($.getppid()).activateWithOptions(2);",
		})
	end
end

return {
	name = "mux",
	description = "Domain management and workspace switching",

	deps = { "zoxide" },

	opts = {
		default_workspace = "~",
		workspaces = {}, -- Active workspaces, zoxide and ~/Workspaces (two levels).
		hosts = {}, -- SSH config, readable known_hosts and the current tailnet.

		-- Keybindings
		term_mod = wezmacs.config.term_mod,
		term_alt_mod = wezmacs.config.term_mod .. "|ALT",
		gui_mod = wezmacs.config.gui_mod,
		ctrl_mod = wezmacs.config.ctrl_mod,
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
				action = wezterm.action_callback(function(window, pane)
					local tab, _ = pane:move_to_new_tab()
					tab:activate()
				end),
				desc = "wezterm/move-pane-to-tab",
			},
			{
				key = "W",
				mods = "LEADER",
				action = wezterm.action_callback(function(_, pane)
					local _, window = pane:move_to_new_window()
					local gui_window = window:gui_window()
					if gui_window then
						gui_window:focus()
					end
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
				action = workspaces.switch_workspace(opts.workspaces),
				desc = "workspace-switch",
			},
			{
				key = "S",
				mods = "LEADER",
				action = workspaces.switch_to_prev_workspace(),
				desc = "workspace-switch-prev",
			},
			{
				key = "d",
				mods = "LEADER",
				action = hosts.switch_host(opts.hosts),
				desc = "ssh-host-switch",
			},
		}
	end,

	setup = function(config, opts)
		config.default_workspace = opts.default_workspace

		-- Focus only explicit launcher windows, never ordinary local startup.
		wezterm.on("gui-attached", function(domain)
			local name = domain:name()
			if name == "local" and os.getenv("WEZMACS_RAYCAST_NEW_WINDOW") == "1" then
				-- Native local startup can hold a mux window lock here. Defer
				-- until rendering; do not enumerate windows in this callback.
				wezterm.GLOBAL.wezmacs_raycast_focus_pending = true
				return
			end
			if not name:match("^SSH to ") then
				return
			end
			local workspace = wezterm.mux.get_active_workspace()
			for _, window in ipairs(wezterm.mux.all_windows()) do
				if window:get_workspace() == workspace then
					local gui = window:gui_window()
					if gui then
						focus_gui(gui)
						return
					end
				end
			end
		end)

		-- One source of status truth: this also follows previous-workspace toggles.
		wezterm.on("update-status", function(window)
			if wezterm.GLOBAL.wezmacs_raycast_focus_pending then
				wezterm.GLOBAL.wezmacs_raycast_focus_pending = nil
				focus_gui(window)
			end
			local workspace = window:active_workspace()
			local name = workspace:match("([^/\\]+)$") or workspace
			window:set_right_status(wezterm.format({ { Text = name .. "  " } }))
		end)
	end,
}
