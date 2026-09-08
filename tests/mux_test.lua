package.path = "./?.lua;./?/init.lua;" .. package.path
local plugin_loads = 0
local events, event_count = {}, 0
package.preload["wezmacs.modules.mux.launcher"] = function() error("removed mailbox must not be loaded") end
package.loaded.wezterm = {
	GLOBAL = {},
	action = setmetatable({}, {
		__index = function(_, name)
			return function(...) return { name, ... } end
		end,
	}),
	action_callback = function(fn) return fn end,
	on = function(event, callback)
		event_count = event_count + 1
		events[event] = callback
	end,
	format = function(items) return items end,
	plugin = {
		require = function()
			plugin_loads = plugin_loads + 1
			error("mux must not depend on an external plugin")
		end,
	},
}
package.loaded.wezmacs = { config = { term_mod = "CTRL|SHIFT", gui_mod = "SUPER", ctrl_mod = "CTRL" } }
package.loaded["wezmacs.modules.mux.workspaces"] = {
	switch_workspace = function(opts) return { workspace_opts = opts } end,
	switch_to_prev_workspace = function() return { previous = true } end,
}
package.loaded["wezmacs.modules.mux.hosts"] = {
	switch_host = function(opts) return { host_opts = opts } end,
}
local getenv, focus_marker = os.getenv, nil
rawset(os, "getenv", function(name)
	if name == "WEZMACS_RAYCAST_NEW_WINDOW" then
		return focus_marker
	end
	return getenv(name)
end)
local mod = require("wezmacs.modules.mux")
assert(plugin_loads == 0, "requiring mux must not load plugins or discover external sources")
local opts = {}
for k, v in pairs(mod.opts) do
	opts[k] = v
end
opts.workspaces = { root = "/fixtures/projects" }
opts.hosts = { tailscale_path = "/fixtures/tailscale" }
local by_key = {}
for _, key in ipairs(mod.keys(opts)) do
	if key.mods == "LEADER" then
		by_key[key.key] = key
	end
end
local focused = false
by_key.W.action({}, {
	move_to_new_window = function()
		return {}, {
			gui_window = function()
				return { focus = function() focused = true end }
			end,
		}
	end,
})
assert(focused, "must focus the GUI window, not call nonexistent MuxWindow.activate")
print("PASS move-pane action focuses the GUI window")
assert(plugin_loads == 0, "building mux keys must not load plugins or query sources")
assert(by_key.s.action.workspace_opts == opts.workspaces, "workspace binding must receive source options")
assert(by_key.S.action.previous, "previous workspace shortcut must remain")
assert(by_key.d and by_key.d.action.host_opts == opts.hosts, "Leader+d must open the native SSH host picker")
assert(by_key.d.desc == "ssh-host-switch", "host binding needs command palette metadata")
print("PASS switcher bindings route options without loading plugins")
local config = { keys = { { existing = true } } }
mod.setup(config, opts)
assert(plugin_loads == 0, "mux setup must not load a domain plugin")
assert(opts.quick_domains == nil, "removed plugin options must not be exposed")
assert(#config.keys == 1 and config.keys[1].existing, "setup preserves existing keys")
assert(not by_key.D and not by_key["|"] and not by_key._, "removed domain shortcuts stay unbound")
assert(config.default_workspace == opts.default_workspace)
assert(events["update-status"], "one workspace status callback must work without theme colors")
local status
local window = {
	active_workspace = function() return "~/Workspaces/example/project" end,
	set_right_status = function(_, value) status = value end,
}
local pane = {}
events["update-status"](window, pane)
assert(event_count == 2, "one startup focus event and one shared status event")
assert(events["gui-attached"], "SSH startup must request focus in the new GUI")
local focus_count, activations = 0, {}
package.loaded.wezterm.target_triple = "aarch64-apple-darwin"
package.loaded.wezterm.run_child_process = function(argv)
	activations[#activations + 1] = argv
	return true, "", ""
end
package.loaded.wezterm.mux = {
	get_active_workspace = function() return "current" end,
	all_windows = function()
		return {
			{ get_workspace = function() return "other" end, gui_window = function() error("inactive workspace") end },
			{
				get_workspace = function() return "current" end,
				gui_window = function()
					return { focus = function() focus_count = focus_count + 1 end }
				end,
			},
		}
	end,
}
events["gui-attached"]({ name = function() return "local" end })
assert(focus_count == 0, "ordinary local startup must not steal focus")
events["gui-attached"]({ name = function() return "SSH to alice@server.example" end })
assert(focus_count == 1, "SSH startup focuses exactly its active workspace window")
assert(#activations == 1, "macOS SSH startup must activate its own process")
assert(activations[1][1] == "/usr/bin/osascript" and activations[1][3] == "JavaScript")
assert(activations[1][5]:find("getppid", 1, true), "activation targets only the helper's parent GUI")
package.loaded.wezterm.target_triple = "x86_64-unknown-linux-gnu"
events["gui-attached"]({ name = function() return "SSH to host" end })
assert(focus_count == 2 and #activations == 1, "non-macOS keeps native focus without an Apple helper")
focus_marker = "1"
package.loaded.wezterm.target_triple = "aarch64-apple-darwin"
local all_windows = package.loaded.wezterm.mux.all_windows
package.loaded.wezterm.mux.all_windows = function() error("local gui-attached holds a native window lock") end
events["gui-attached"]({ name = function() return "local" end })
assert(focus_count == 2 and #activations == 1, "local activation waits for a rendered window")
window.focus = function() focus_count = focus_count + 1 end
events["update-status"](window, pane)
assert(focus_count == 3 and #activations == 2, "explicit Raycast local window becomes frontmost once rendered")
events["update-status"](window, pane)
assert(focus_count == 3 and #activations == 2, "subsequent status updates must not steal focus")
package.loaded.wezterm.mux.all_windows = all_windows
rawset(os, "getenv", getenv)
print("PASS SSH startup focus is scoped to its own GUI and active workspace")
assert(status[1].Text == "project  ", "status must reflect the active workspace, including previous-workspace toggles")
print("PASS plugin-free mux keeps workspace status and one-shot focus")
