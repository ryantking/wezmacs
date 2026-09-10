-- Run via scripts/native-regressions.sh: real actions/formatting, no GUI or discovery.
local wezterm = require("wezterm")
local ok, config = xpcall(function()
	local root = os.getenv("WEZMACS_SMOKE_ROOT") or "."
	package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
	package.preload.wezmacs = function() error("standalone helper must not load framework config") end
	local calls = 0
	wezterm.run_child_process = function(argv)
		assert(table.concat(argv, "|") == "/test/zoxide|query|-l", "only stubbed queries are allowed")
		calls = calls + 1
		return true, "/ranked\n", ""
	end
	wezterm.background_child_process = function() error("background process forbidden") end
	wezterm.read_dir = function(path)
		assert(path == "/ranked" or path == "/test/root", "unexpected directory read")
		return {}
	end
	wezterm.mux.get_workspace_names = function() return { "remote/", "~" } end
	local mod = require("wezmacs.modules.mux.workspaces")
	local opts = { root = "/test/root", zoxide_path = "/test/zoxide" }
	local open = mod.switch_workspace(opts)
	assert(calls == 0, "action construction must be lazy")
	local pane, actions = {}, {}
	local win = { config = { colors = { ansi = { "#000000", "#aa0000", "#12ab34", "#aaaa00", "#5678ef" } } } }
	function win:active_workspace() return "~" end
	function win:effective_config() return self.config end
	function win:perform_action(action, target)
		assert(target == pane)
		actions[#actions + 1] = action
	end
	wezterm.emit(open.EmitEvent, win, pane)
	local selector = assert(actions[1].InputSelector, "native callback must construct InputSelector")
	assert(selector.fuzzy and selector.fuzzy_description == "Workspaces: ")
	assert(selector.description == "Select a workspace")
	local icon = assert(wezterm.nerdfonts.md_dock_window)
	assert(icon == "󱂬", "must match upstream smart_workspace_switcher glyph")
	local function label(color, name)
		return wezterm.format({
			{ Foreground = { Color = color } },
			{ Text = icon },
			-- Native Default is omitted from the community FormatItem annotation.
			---@diagnostic disable-next-line: assign-type-mismatch
			{ Foreground = "Default" },
			{ Text = " " .. name },
		})
	end
	local choices = selector.choices
	assert(#choices == 3)
	assert(choices[1].id == "~" and choices[2].id == "remote/" and choices[3].id == "/ranked")
	assert(choices[1].label == label("#12ab34", "~"), "current label must have green icon and default text")
	assert(choices[2].label == label("#5678ef", "remote/"), "other live label must have blue icon and default text")
	local blank = string.rep(" ", wezterm.column_width(icon)) .. " /ranked"
	assert(choices[3].label == wezterm.format({ { Text = blank } }), "inactive icon slot must align")
	io.stderr:write("native green label: ", string.format("%q", choices[1].label), "\n")
	io.stderr:write("native blue label: ", string.format("%q", choices[2].label), "\n")
	io.stderr:write("native icon width: ", wezterm.column_width(icon), "\n")
	local plain = mod.get_choices(opts)
	assert(plain[1].id == "remote/" and plain[1].label == "remote/")
	assert(plain[2].label == "~" and plain[3].label == "/ranked", "shared API must remain undecorated")
	wezterm.emit(selector.action.EmitEvent, win, pane, nil, nil)
	assert(#actions == 1, "cancellation must not perform an action")
	wezterm.emit(selector.action.EmitEvent, win, pane, "~", "ignored decorated label")
	assert(#actions == 1, "current workspace remains a no-op")
	wezterm.emit(selector.action.EmitEvent, win, pane, "remote/", "ignored decorated label")
	assert(actions[2].SwitchToWorkspace.name == "remote/")
	assert(actions[2].SwitchToWorkspace.spawn == nil, "live selection must not spawn")
	assert(calls == 2, "selection must not write zoxide history")
	wezterm.nerdfonts = nil
	win.config = {}
	wezterm.emit(open.EmitEvent, win, pane)
	local fallback = assert(actions[3].InputSelector)
	for index, color in ipairs({ "Green", "Blue" }) do
		local name = index == 1 and "~" or "remote/"
		assert(fallback.choices[index].label == wezterm.format({
			{ Foreground = { AnsiColor = color } },
			{ Text = "*" },
			---@diagnostic disable-next-line: assign-type-mismatch
			{ Foreground = "Default" },
			{ Text = " " .. name },
		}), "missing optional font/palette data must use ASCII and ANSI state colors")
	end
	assert(fallback.choices[3].label == wezterm.format({ { Text = "  /ranked" } }))
	io.stderr:write("native fallback label: ", string.format("%q", fallback.choices[1].label), "\n")
	local built = wezterm.config_builder()
	---@cast built WezmacsConfigBuilder
	built:set_strict_mode(true)
	built.keys = {
		{ key = "F22", mods = "CTRL|SHIFT|ALT|SUPER", action = actions[3] },
		{ key = "F23", mods = "CTRL|SHIFT|ALT|SUPER", action = actions[1] },
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
	print("PASS native workspace picker styling")
	return validated
end, tostring)
if not ok then
	io.stderr:write(tostring(config), "\n")
	os.exit(1)
end
return config
