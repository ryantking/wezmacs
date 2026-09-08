package.path = "./?.lua;./?/init.lua;" .. package.path

local passed = 0
local function test(name, fn)
	fn()
	passed = passed + 1
	print("PASS " .. name)
end

local function equal(actual, expected, message)
	assert(
		actual == expected,
		(message or "value differs") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)
	)
end

local function window(id, current)
	local win = { actions = {}, current = current }
	function win:window_id() return id end
	function win:active_workspace() return self.current end
	function win:perform_action(action, pane)
		self.actions[#self.actions + 1] = { action = action, pane = pane }
		if action.kind == "switch" then
			self.current = action.value.name
		end
	end
	return win
end

local function fixture()
	local state = { names = { "~", "ssh:server" }, calls = {}, reads = {}, dirs = {}, output = "" }
	local wezterm = {
		home_dir = "/home/test",
		target_triple = "aarch64-apple-darwin",
		GLOBAL = {},
		mux = { get_workspace_names = function() return state.names end },
		action_callback = function(fn) return fn end,
		action = {
			InputSelector = function(value) return { kind = "selector", value = value } end,
			SwitchToWorkspace = function(value) return { kind = "switch", value = value } end,
		},
		read_dir = function(path)
			state.reads[path] = (state.reads[path] or 0) + 1
			assert(state.dirs[path], "not a readable directory")
			return state.dirs[path]
		end,
		run_child_process = function(argv)
			state.calls[#state.calls + 1] = argv
			return true, state.output, ""
		end,
	}
	package.loaded.wezterm = wezterm
	package.loaded["wezmacs.modules.mux.workspaces"] = nil
	local mod = require("wezmacs.modules.mux.workspaces")
	return mod, state, wezterm
end

test("picker marks running workspaces and promotes current without changing IDs", function()
	local mod, state = fixture()
	state.names = { "alpha", "~" }
	state.output = "/ranked\n"
	state.dirs["/ranked"] = {}
	local win = window(1, "~")
	mod.switch_workspace()(win, {})
	local choices = win.actions[1].action.value.choices
	equal(choices[1].id, "~")
	equal(choices[1].label, "~ [current]")
	equal(choices[2].id, "alpha")
	equal(choices[2].label, "alpha [running]")
	equal(choices[3].label, "/ranked")
end)

test("explicit live inventory is isolated from the native mux, including an empty list", function()
	local mod, _, wezterm = fixture()
	wezterm.mux.get_workspace_names = function() error("must not query native mux for supplied inventory") end
	local choices = mod.get_choices(nil, { "remote/", "~" })
	equal(#choices, 2)
	equal(choices[1].id, "remote/")
	equal(choices[2].id, "~")
	equal(#mod.get_choices(nil, {}), 0)
end)

test("collects active workspaces first without load-time discovery", function()
	local mod, state = fixture()
	equal(#state.calls, 0)
	equal(next(state.reads), nil)
	local choices = mod.get_choices()
	equal(#choices, 2)
	equal(choices[1].id, "~")
	equal(choices[2].id, "ssh:server")
end)

test("merges ranked zoxide directories with canonical active dedup", function()
	local mod, state = fixture()
	local path = "/home/test/O'Reilly $(touch nope); [literal]"
	state.names = { "~/Workspaces/active", "/home/test/Workspaces/active/", "ssh:server" }
	state.dirs[path] = {}
	state.dirs["/home/testing"] = {}
	state.output = "/home/test/Workspaces/active/\n" .. path .. "\n/missing\n/a-file\n" .. path .. "\n/home/testing\n"
	local choices = mod.get_choices()
	equal(#choices, 4)
	equal(choices[1].id, "~/Workspaces/active")
	equal(choices[2].id, "ssh:server")
	equal(choices[3].id, path)
	equal(choices[3].label, "~/O'Reilly $(touch nope); [literal]")
	equal(choices[4].label, "/home/testing", "home prefix must end on a component boundary")
	equal(table.concat(state.calls[1], "|"), "zoxide|query|-l")
end)

test("scans exactly two sorted directory levels after ranked paths", function()
	local mod, state = fixture()
	local root = "/home/test/Workspaces"
	state.names = { "~/Workspaces/Z" }
	state.output = root .. "/Z\n/ranked\n"
	state.dirs["/ranked"] = {}
	state.dirs[root] = { root .. "/Z", root .. "/A", root .. "/file" }
	state.dirs[root .. "/Z"] = { root .. "/Z/repo" }
	state.dirs[root .. "/A"] = { root .. "/A/two words", root .. "/A/file" }
	state.dirs[root .. "/Z/repo"] = { root .. "/Z/repo/too-deep" }
	state.dirs[root .. "/A/two words"] = {}
	state.dirs[root .. "/Z/repo/too-deep"] = {}
	for _, noise in ipairs({ ".git", ".hidden", "node_modules", "target", "build", "dist", "__pycache__", "coverage" }) do
		for _, parent in ipairs({ root, root .. "/A" }) do
			table.insert(state.dirs[parent], parent .. "/" .. noise)
			state.dirs[parent .. "/" .. noise] = {}
		end
	end
	local choices = mod.get_choices()
	local ids = {}
	for _, choice in ipairs(choices) do
		ids[#ids + 1] = choice.id
	end
	equal(
		table.concat(ids, "|"),
		"~/Workspaces/Z|/ranked|" .. root .. "/A|" .. root .. "/A/two words|" .. root .. "/Z/repo"
	)
	equal(state.reads[root .. "/Z/repo/too-deep"], nil)
	for path, count in pairs(state.reads) do
		equal(count, 1, "directory is read once per collection")
		assert(not path:match("/node_modules$") and not path:match("/%.git$"), "noise must not be traversed")
	end
end)

test("accepts literal root and executable overrides", function()
	local mod, state = fixture()
	local root = "/home/test/My roots [x]"
	local executable = "/tools/O'Reilly; zoxide"
	state.dirs[root] = { root .. "/repo" }
	state.dirs[root .. "/repo"] = {}
	local choices = mod.get_choices({ root = "~/My roots [x]/", zoxide_path = executable })
	equal(#choices, 3)
	equal(choices[3].id, root .. "/repo")
	equal(table.concat(state.calls[1], "|"), executable .. "|query|-l")
	equal(state.reads["/home/test/Workspaces"], nil)
end)

test("resolves GUI PATH fallbacks with protected direct argv", function()
	local mod, state, wezterm = fixture()
	wezterm.run_child_process = function(argv)
		state.calls[#state.calls + 1] = argv
		if argv[1] ~= "/home/test/.local/bin/zoxide" then
			error("not found")
		end
		return true, "/ranked\n", ""
	end
	state.dirs["/ranked"] = {}
	local choices = mod.get_choices()
	equal(#choices, 3)
	local expected = { "zoxide", "/opt/homebrew/bin/zoxide", "/usr/local/bin/zoxide", "/home/test/.local/bin/zoxide" }
	equal(#state.calls, #expected)
	for index, bin in ipairs(expected) do
		equal(table.concat(state.calls[index], "|"), bin .. "|query|-l")
	end
	state.calls = {}
	wezterm.target_triple = "x86_64-unknown-linux-gnu"
	equal(#mod.get_choices(), 3)
	equal(#state.calls, 2, "Homebrew fallbacks are macOS-only")
end)

test("opens a fresh fuzzy picker lazily even without zoxide or root", function()
	local mod, state, wezterm = fixture()
	wezterm.run_child_process = function(argv)
		state.calls[#state.calls + 1] = argv
		error("missing executable")
	end
	local open = mod.switch_workspace({ zoxide_path = "/missing/zoxide", root = "/missing/root" })
	local win, pane = window(1, "~"), {}
	equal(#state.calls, 0)
	equal(next(state.reads), nil)
	open(win, pane)
	local picker = win.actions[1].action
	equal(picker.kind, "selector")
	equal(picker.value.fuzzy, true)
	equal(picker.value.fuzzy_description, "Workspaces: ")
	equal(picker.value.description, "Select a workspace")
	equal(#picker.value.choices, 2)
	equal(win.actions[1].pane, pane)
	equal(#state.calls, 1, "explicit executable must not silently fall back")
	state.names = { "later" }
	open(win, pane)
	equal(win.actions[2].action.value.choices[1].id, "later")
	equal(#state.calls, 2, "each opening refreshes discovery")
end)

test("focuses an existing workspace without spawning or using its label", function()
	local mod, state = fixture()
	local win, pane = window(1, "~"), { remote = true }
	mod.switch_workspace()(win, pane)
	local select = win.actions[1].action.value.action
	assert(type(select) == "function", "picker must have a selection callback")
	select(win, pane, "ssh:server", "decorated label, never a name")
	equal(#win.actions, 2)
	equal(win.actions[2].action.kind, "switch")
	equal(win.actions[2].action.value.name, "ssh:server")
	equal(win.actions[2].action.value.spawn, nil)
	equal(win.actions[2].pane, pane)
	equal(#state.calls, 1, "existing workspace must not be added to zoxide")
end)

test("creates local workspaces with literal cwd, unique names and safe zoxide add", function()
	local mod, state = fixture()
	local path = "/home/test/O'Reilly $(touch nope); [literal]/repo"
	local other = "/home/test/Workspaces/repo"
	state.output = path .. "\n"
	state.dirs[path] = {}
	state.dirs["/home/test/Workspaces"] = { other }
	state.dirs[other] = {}
	local win, pane = window(1, "~"), { remote = true }
	mod.switch_workspace({ zoxide_path = "/tools/zoxide" })(win, pane)
	local select = win.actions[1].action.value.action
	select(win, pane, path, "formatted name")
	equal(#win.actions, 2)
	local command = win.actions[2].action.value
	equal(command.name, "~/O'Reilly $(touch nope); [literal]/repo")
	equal(command.spawn.cwd, path)
	equal(command.spawn.domain.DomainName, "local", "remote pane must not determine spawn domain")
	equal(table.concat(state.calls[2], "|"), "/tools/zoxide|add|--|" .. path)
	equal(#state.calls[2], 4)
	select(win, pane, other, "formatted name")
	equal(win.actions[3].action.value.name, "~/Workspaces/repo", "same basename must not collide")
	equal(state.calls[3][4], other)
end)

test("does not resurrect stale selections or act on canceled or unknown choices", function()
	local mod, state = fixture()
	local path = "/home/test/vanishing"
	state.names = { "~", "closed" }
	state.dirs[path] = {}
	state.output = path .. "\n"
	local win, pane = window(1, "~"), {}
	mod.switch_workspace()(win, pane)
	local select = win.actions[1].action.value.action
	state.names = { "~", "not-in-picker" }
	state.dirs[path] = nil
	select(win, pane, nil, nil)
	select(win, pane, "closed", "closed")
	select(win, pane, "/unknown", "unknown")
	select(win, pane, path, "vanishing")
	select(win, pane, "not-in-picker", "unknown")
	equal(#win.actions, 1, "no switch or spawn for stale/unknown choices")
	equal(#state.calls, 1, "no zoxide writes on cancellation")
end)

test("rechecks canonical workspace names when a directory becomes active", function()
	local mod, state = fixture()
	local path = "/home/test/Workspaces/repo"
	state.output = path .. "\n"
	state.dirs[path] = {}
	local win, pane = window(1, "~"), {}
	mod.switch_workspace()(win, pane)
	state.names = { "~", "~/Workspaces/repo" }
	win.actions[1].action.value.action(win, pane, path, "formatted")
	equal(win.actions[2].action.value.name, "~/Workspaces/repo")
	equal(win.actions[2].action.value.spawn, nil, "a workspace created while picker was open must only be focused")
	equal(#state.calls, 1)
end)

test("previous survives GUI window remapping to a different mux window", function()
	local mod = fixture()
	local win, pane = window(10, "~"), {}
	local mux_ids = { ["~"] = 10, ["ssh:server"] = 20 }
	-- Native reconciliation reuses the GUI window for the destination mux window.
	function win:window_id() return mux_ids[self.current] end
	mod.switch_workspace()(win, pane)
	equal(win:window_id(), 10)
	win.actions[1].action.value.action(win, pane, "ssh:server", "label")
	equal(win:window_id(), 20)
	mod.switch_to_prev_workspace()(win, pane)
	equal(win.current, "~", "previous must survive a changed mux-window ID")
	equal(win:window_id(), 10)
	mod.switch_to_prev_workspace()(win, pane)
	equal(win.current, "ssh:server")
	equal(win:window_id(), 20)
	equal(#win.actions, 4)
end)

test("previous is shared by GUI-client windows across helper reloads", function()
	local mod, state, wezterm = fixture()
	state.names = { "~", "ssh:server", "beta" }
	local one, two, pane = window(1, "~"), window(2, "~"), {}
	local current = "~"
	for _, win in ipairs({ one, two }) do
		-- Native active_workspace belongs to the GUI client, not each window.
		function win:active_workspace() return current end
		local perform_action = win.perform_action
		function win:perform_action(action, selected_pane)
			perform_action(self, action, selected_pane)
			if action.kind == "switch" then
				current = action.value.name
			end
		end
	end
	local open = mod.switch_workspace()
	open(one, pane)
	one.actions[1].action.value.action(one, pane, "ssh:server", "label")
	equal(two:active_workspace(), "ssh:server")
	open(two, pane)
	two.actions[1].action.value.action(two, pane, "beta", "label")
	equal(one:active_workspace(), "beta")
	package.loaded["wezmacs.modules.mux.workspaces"] = nil
	mod = require("wezmacs.modules.mux.workspaces")
	local previous = mod.switch_to_prev_workspace()
	previous(one, pane)
	equal(one:active_workspace(), "ssh:server")
	previous(two, pane)
	equal(two:active_workspace(), "beta")
	previous(one, pane)
	equal(one:active_workspace(), "ssh:server")
	equal(one.actions[3].action.value.spawn, nil)
	equal(two.actions[3].action.value.spawn, nil)
	equal(#state.calls, 2, "previous does not discover processes")
	for key, value in pairs(wezterm.GLOBAL) do
		equal(type(key), "string")
		equal(type(value), "string", "only serializable client-wide history")
	end
end)

test("previous no-ops when unset or closed instead of creating a workspace", function()
	local mod, state = fixture()
	local win, pane = window(1, "~"), {}
	local previous = mod.switch_to_prev_workspace()
	previous(win, pane)
	equal(#win.actions, 0, "unset previous must not spawn a random workspace")
	mod.switch_workspace()(win, pane)
	win.actions[1].action.value.action(win, pane, "ssh:server", "label")
	state.names = { "ssh:server" }
	previous(win, pane)
	equal(#win.actions, 2, "closed previous must not be resurrected")
	equal(win.current, "ssh:server")
	equal(#state.calls, 1)
end)

test("selecting current workspace preserves history and previous-to-current is a no-op", function()
	local mod = fixture()
	local win, pane = window(1, "~"), {}
	mod.switch_workspace()(win, pane)
	local select = win.actions[1].action.value.action
	select(win, pane, "ssh:server", "label")
	select(win, pane, "ssh:server", "label")
	equal(#win.actions, 2, "selecting current must not replace previous")
	mod.switch_to_prev_workspace()(win, pane)
	equal(win.current, "~")
	win.current = "ssh:server" -- an external action already returned to the previous
	mod.switch_to_prev_workspace()(win, pane)
	equal(#win.actions, 3, "previous equal to current is a no-op")
end)

test("seeds an empty zoxide database for scanned selections without surfacing add failures", function()
	local mod, state, wezterm = fixture()
	local root, path = "/home/test/Workspaces", "/home/test/Workspaces/repo"
	state.dirs[root], state.dirs[path], state.dirs["/ignore"] = { path }, {}, {}
	wezterm.run_child_process = function(argv)
		state.calls[#state.calls + 1] = argv
		if argv[2] == "add" then
			error("database unavailable")
		end
		return false, "/ignore\n", "no match"
	end
	local win, pane = window(1, "~"), {}
	mod.switch_workspace({ zoxide_path = "/tools/zoxide" })(win, pane)
	equal(#win.actions[1].action.value.choices, 3, "failed query stdout is ignored")
	win.actions[1].action.value.action(win, pane, path, "label")
	equal(win.current, "~/Workspaces/repo")
	equal(#state.calls, 2, "an empty database still has a resolved executable for add")
	equal(table.concat(state.calls[2], "|"), "/tools/zoxide|add|--|" .. path)
	state.names = { "~", "~/Workspaces/repo" }
	mod.switch_to_prev_workspace()(win, pane)
	equal(win.current, "~", "new workspace history survives zoxide add failure")
end)

test("preserves opaque workspace identifiers while deduplicating home paths", function()
	local mod, state = fixture()
	state.names = { "remote/", "remote", "", "/", "~", "/home/test/" }
	local choices = mod.get_choices()
	equal(#choices, 5)
	for index, name in ipairs({ "remote/", "remote", "", "/", "~" }) do
		equal(choices[index].id, name)
	end
end)

print("PASS workspace tests: " .. passed)
