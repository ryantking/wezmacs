-- Native constructors and emitted callbacks; never launch a process or query a network.
local wezterm = require("wezterm")
local ok, config = xpcall(function()
	local root = os.getenv("WEZMACS_SMOKE_ROOT") or "."
	package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
	wezterm.enumerate_ssh_hosts = function() return { Work = {} } end
	wezterm.run_child_process = function() error("unexpected discovery process") end
	wezterm.background_child_process = function() error("unexpected background process") end
	local hosts = require("wezmacs.modules.mux.hosts")
	local actions, notices = {}, {}
	local reject_splits = false
	local pane = { domain = "local" }
	function pane:get_domain_name() return self.domain end
	local window = {}
	function window:perform_action(action)
		if reject_splits and action.SplitPane then
			error("split rejected")
		end
		actions[#actions + 1] = action
	end
	function window:toast_notification(_, message) notices[#notices + 1] = message end
	local function emit(action, target_pane, ...) wezterm.emit(action.EmitEvent, window, target_pane, ...) end
	local opts = { tailscale = false, known_hosts_files = {} }
	local split_open = hosts.switch_host(opts)
	emit(split_open, pane)
	local selector = assert(actions[1].InputSelector, "native callback must construct InputSelector")
	assert(selector.fuzzy and selector.fuzzy_description == "SSH hosts: ")
	assert(selector.description == "Select an SSH host" and #selector.choices == 1)
	emit(selector.action, pane, nil, nil)
	assert(#actions == 1, "cancellation must not place a pane")
	emit(selector.action, pane, "unknown-id", "untrusted label")
	assert(#actions == 1 and #notices == 1, "unknown selection must not place a pane")
	pane.domain = "remote"
	emit(selector.action, pane, selector.choices[1].id, "untrusted label")
	assert(#actions == 1 and #notices == 2, "submission rechecks local domain")
	pane.domain = "local"
	emit(selector.action, pane, selector.choices[1].id, "untrusted label")
	local split = assert(actions[2].SplitPane, "native split constructor must be used")
	assert(split.direction == "Right" and split.size.Percent == 50)
	assert(split.command.domain == "CurrentPaneDomain")
	assert(table.concat(split.command.args, " | ") == "ssh | -- | Work")
	local tab_open = hosts.switch_host(opts, "tab")
	emit(tab_open, pane)
	local tab_selector = assert(actions[3].InputSelector)
	emit(tab_selector.action, pane, tab_selector.choices[1].id, nil)
	local tab = assert(actions[4].SpawnCommandInNewTab, "native tab constructor must be used")
	assert(tab.domain == "CurrentPaneDomain")
	assert(table.concat(tab.args, " | ") == "ssh | -- | Work")
	local failed = hosts.switch_host(opts)
	reject_splits = true
	emit(failed, pane)
	local failed_selector = actions[5].InputSelector
	emit(failed_selector.action, pane, failed_selector.choices[1].id, nil)
	assert(notices[#notices]:find("Could not start OpenSSH", 1, true))
	local built = wezterm.config_builder()
	---@cast built WezmacsConfigBuilder
	built:set_strict_mode(true)
	built.keys = {
		{ key = "F22", mods = "CTRL|SHIFT|ALT|SUPER", action = actions[2] },
		{ key = "F23", mods = "CTRL|SHIFT|ALT|SUPER", action = actions[4] },
		{
			key = "F24",
			mods = "CTRL|SHIFT|ALT|SUPER",
			action = wezterm.action.SendString("__WEZMACS_REGRESSION_VALIDATED__"),
		},
	}
	local validated = wezterm.config_builder()
	---@cast validated WezmacsConfigBuilder
	validated:set_strict_mode(true)
	for key, value in pairs(built) do
		validated[key] = value
	end
	print("PASS native SSH actions")
	return validated
end, tostring)
if not ok then
	io.stderr:write(tostring(config), "\n")
	os.exit(1)
end
return config
