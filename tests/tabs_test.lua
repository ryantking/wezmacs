package.path = "./?.lua;./?/init.lua;" .. package.path
-- Minimal cell-width seam for these fixtures; also exercised with native WezTerm.
local function cell_width(char)
	local code = utf8.codepoint(char)
	if code == 0x301 then
		return 0
	end
	return ((code >= 0x4e00 and code <= 0x9fff) or code == 0x1f680) and 2 or 1
end
local function column_width(value)
	local width = 0
	for char in value:gmatch(utf8.charpattern) do
		width = width + cell_width(char)
	end
	return width
end
local truncations = 0
package.loaded.wezterm = {
	home_dir = "/home/test",
	nerdfonts = { cod_globe = "<globe>", md_arrow_down_box = "<download>" },
	column_width = column_width,
	truncate_right = function(value, max_width)
		truncations = truncations + 1
		assert(max_width >= 0, "native truncation cannot receive negative widths")
		local chars, width = {}, 0
		for char in value:gmatch(utf8.charpattern) do
			local size = column_width(char)
			if width + size > max_width then
				break
			end
			chars[#chars + 1], width = char, width + size
		end
		return table.concat(chars)
	end,
}
local hooks = require("wezmacs.modules.tabs.hooks")
-- Titles are user/application content, not an executable-name protocol.

local function text(items)
	local parts = {}
	for _, item in ipairs(items) do
		parts[#parts + 1] = item.Text or ""
	end
	return table.concat(parts)
end

for _, title in ipairs({ "nvim - my notes", "htop", "claude: a task", "  personal label  " }) do
	assert(
		text(hooks.format_tab_title({ tab_title = title, active_pane = {} })) == " 1 " .. title .. " ",
		"explicit tab title must remain verbatim: " .. title
	)
end
print("PASS explicit titles remain verbatim")

for _, title in ipairs({
	"nvim - main.lua [+]",
	"htop",
	"curl - download",
	"wget - download",
	"Claude: review tests",
	"未知 application — task",
}) do
	local tab = { active_pane = { title = title, foreground_process_name = "/usr/bin/node" } }
	assert(text(hooks.format_tab_title(tab)) == " 1 " .. title .. " ", "OSC title must survive: " .. title)
end
print("PASS application OSC titles remain verbatim")

local fallbacks = {
	{ {}, "Shell" },
	{ { title = "", foreground_process_name = "" }, "Shell" },
	{ { foreground_process_name = "/opt/bin/nvim" }, "Neovim" },
	{ { foreground_process_name = "C:\\Tools\\NVIM.EXE" }, "Neovim" },
	{ { foreground_process_name = "/opt/bin/claude" }, "Claude" },
	{ { foreground_process_name = "/opt/bin/codex" }, "Codex" },
	{ { foreground_process_name = "/opt/bin/opencode" }, "OpenCode" },
	{ { foreground_process_name = "/opt/bin/hermes" }, "Hermes" },
	{ { foreground_process_name = "/bin/node" }, "node" },
	{ { foreground_process_name = "/bin/python3" }, "python3" },
	{ { foreground_process_name = "/bin/not-claude" }, "not-claude" },
	{ { foreground_process_name = "/bin/zsh", current_working_dir = { file_path = "/project" } }, "project" },
	{ { current_working_dir = { file_path = "/home/test/" } }, "~" },
	{ { current_working_dir = { file_path = "/" } }, "/" },
	{ { current_working_dir = { file_path = "" } }, "Shell" },
	{ { current_working_dir = {} }, "Shell" },
	{ { current_working_dir = { file_path = "/work/project///" } }, "project" },
	{ { current_working_dir = { file_path = "C:\\work\\project\\" } }, "project" },
	{ { current_working_dir = { file_path = "C:\\" } }, "C:/" },
}
for _, case in ipairs(fallbacks) do
	assert(
		text(hooks.format_tab_title({ tab_title = "", active_pane = case[1] })) == " 1 " .. case[2] .. " ",
		"metadata fallback must be " .. case[2]
	)
end
assert(text(hooks.format_tab_title({})) == " 1 Shell ", "missing active pane must be safe")
print("PASS executable, cwd and shell fallbacks")

assert(text(hooks.format_tab_title({ tab_index = 4, tab_title = "Task" })) == " 5 Task ", "tab numbers are one-based")
assert(
	text(hooks.format_tab_title({ tab_title = "Task", active_pane = { is_zoomed = true } })) == " 1 Task [Z] ",
	"active snapshot zoom must be visible"
)
assert(
	text(hooks.format_tab_title({ tab_title = "Task", panes = { {}, { is_zoomed = true } } })) == " 1 Task [Z] ",
	"zoom in pane snapshots must be visible"
)
print("PASS tab numbers and zoom indicators")

local attention = {
	tab_title = "Codex: review",
	is_active = false,
	active_pane = { has_unseen_output = false },
	panes = { { has_unseen_output = false }, { has_unseen_output = true } },
}
local palette = { colors = { ansi = { "black", "red", "green", "yellow", "#7aa2f7" } } }
local output = hooks.format_tab_title(attention, {}, {}, palette)
assert(text(output) == " 1 Codex: review · ", "unseen output in any inactive pane needs a subtle dot")
assert(output[1].Text == " 1 Codex: review ", "normal label must inherit native colors")
assert(output[2].Foreground.Color == "#7aa2f7" and output[3].Text == "· ", "color only the attention marker")
attention.is_active = true
output = hooks.format_tab_title(attention, {}, {}, palette)
assert(#output == 1 and text(output) == " 1 Codex: review ", "active tabs must not show unseen-output attention")
attention.is_active = false
attention.panes = nil
attention.active_pane.has_unseen_output = true
assert(
	text(hooks.format_tab_title(attention)) == " 1 Codex: review · ",
	"active pane snapshot also carries unseen output"
)
attention.active_pane.has_unseen_output = false
assert(
	text(hooks.format_tab_title(attention)) == " 1 Codex: review ",
	"no output must mean no attention or invented state"
)
print("PASS inactive unseen-output marker and native colors")

local long_tab = {
	tab_index = 9,
	tab_title = "未知🚀 café task " .. string.rep("long", 12),
	is_active = false,
	active_pane = { is_zoomed = true, has_unseen_output = true },
}
for width = 0, 40 do
	local rendered = text(hooks.format_tab_title(long_tab, {}, {}, { use_fancy_tab_bar = false }, false, width))
	assert(utf8.len(rendered), "clipping must not split UTF-8")
	assert(column_width(rendered) <= width, "retro title exceeds cell budget " .. width)
	if width >= 16 then
		assert(rendered:find("[Z] · ", 1, true), "reserve room for zoom and attention at ordinary widths")
	end
end
assert(truncations > 0, "retro clipping must use native truncate_right")
local before = truncations
local fancy = text(hooks.format_tab_title(long_tab, {}, {}, { use_fancy_tab_bar = true }, false, 1))
assert(fancy == " 10 " .. long_tab.tab_title .. " [Z] · ", "fancy bar width is native-managed, not max_width cells")
assert(truncations == before, "do not truncate fancy titles using the retro width contract")
print("PASS native Unicode clipping and fancy/retro width contracts")

local bare_titles = {
	{ "zsh", "project" },
	{ "bash", "project" },
	{ "fish", "project" },
	{ "pwsh.exe", "project" },
	{ "nvim", "Neovim · project" },
	{ "NVIM.EXE", "Neovim · project" },
	{ "claude", "Claude · project" },
	{ "codex", "Codex · project" },
	{ "opencode", "OpenCode · project" },
	{ "hermes", "Hermes · project" },
	{ "node", "node" },
	{ "python", "python" },
	{ "not-claude", "not-claude" },
}
for _, case in ipairs(bare_titles) do
	local pane = { title = case[1], current_working_dir = { file_path = "/work/project" } }
	setmetatable(pane, {
		__index = function(_, key)
			assert(key ~= "foreground_process_name", "a sufficient OSC title must not query foreground metadata")
		end,
	})
	assert(
		text(hooks.format_tab_title({ active_pane = pane })) == " 1 " .. case[2] .. " ",
		"bare executable title must expose useful context: " .. case[1]
	)
end
assert(
	text(hooks.format_tab_title({ active_pane = { title = "nvim" } })) == " 1 Neovim ",
	"missing app cwd must not append Shell"
)
assert(
	text(hooks.format_tab_title({ active_pane = { title = "zsh" } })) == " 1 zsh ",
	"missing shell cwd must retain shell name"
)
local guarded_pane = setmetatable({ title = "nvim - init.lua [+]" }, {
	__index = function(_, key)
		assert(
			key ~= "foreground_process_name" and key ~= "current_working_dir",
			"informative titles must avoid lazy metadata"
		)
	end,
})
assert(text(hooks.format_tab_title({ active_pane = guarded_pane })) == " 1 nvim - init.lua [+] ")
assert(
	text(hooks.format_tab_title({ tab_title = "nvim", active_pane = guarded_pane })) == " 1 nvim ",
	"explicit bare app titles must remain untouched"
)
print("PASS bare app/shell titles and lazy metadata boundaries")

assert(
	text(hooks.format_tab_title({ active_pane = { title = "curl" } })) == " 1 <globe> curl ",
	"curl must retain its available native cod_globe icon and text"
)
assert(
	text(hooks.format_tab_title({ active_pane = { foreground_process_name = "/bin/wget" } })) == " 1 <download> wget ",
	"wget must retain its available native md_arrow_down_box icon and text"
)
assert(text(hooks.format_tab_title({ tab_title = "curl" })) == " 1 curl ", "manual curl must not get an icon")
print("PASS curl/wget native icons with legible executable labels")

local events = {}
package.loaded.wezterm.on = function(name, callback) events[#events + 1] = { name = name, callback = callback } end
package.loaded.wezterm.action = setmetatable({}, {
	__index = function(_, name)
		return function(value) return { [name] = value } end
	end,
})
package.loaded.wezmacs = { config = { term_mod = "ALT", gui_mod = "SUPER", ctrl_mod = "CTRL" } }
local tabs = require("wezmacs.modules.tabs")
local opts = tabs.opts()
local expected_options = {
	enable_tab_bar = true,
	use_fancy_tab_bar = true,
	hide_tab_bar_if_only_one_tab = false,
	show_new_tab_button_in_tab_bar = true,
	show_close_tab_button_in_tabs = false,
	tab_max_width = 32,
	tab_bar_at_bottom = false,
	unzoom_on_switch_pane = false,
}
local configured = {}
tabs.setup(configured, opts)
for key, expected in pairs(expected_options) do
	assert(opts[key] == expected and configured[key] == expected, "tab option must be explicit: " .. key)
end
assert(
	#events == 1 and events[1].name == "format-tab-title" and events[1].callback == hooks.format_tab_title,
	"tabs must register only the snapshot render hook"
)
opts.enable_tab_bar, opts.show_new_tab_button_in_tab_bar, opts.show_close_tab_button_in_tabs = false, false, true
tabs.setup(configured, opts)
assert(
	configured.enable_tab_bar == false
		and configured.show_new_tab_button_in_tab_bar == false
		and configured.show_close_tab_button_in_tabs == true,
	"explicit tab button overrides must remain supported"
)
print("PASS explicit fancy single-tab defaults and setup overrides")

local expected_keys = {
	{ "t", "ALT", "SpawnTab", "CurrentPaneDomain", "new" },
	{ "t", "SUPER", "SpawnTab", "CurrentPaneDomain", "new" },
	{ "T", "SUPER|SHIFT", "SpawnTab", "DefaultDomain", "new-default" },
	{ "w", "SUPER", "CloseCurrentTab", { confirm = false }, "close" },
	{ "Tab", "CTRL", "ActivateTabRelative", 1, "next" },
	{ "Tab", "CTRL|SHIFT", "ActivateTabRelative", -1, "prev" },
	{ "[", "SUPER", "ActivateTabRelative", -1, "prev" },
	{ "]", "SUPER", "ActivateTabRelative", 1, "next" },
	{ "PageUp", "CTRL", "ActivateTabRelative", -1, "prev" },
	{ "PageDown", "CTRL", "ActivateTabRelative", 1, "next" },
	{ "PageUp", "CTRL|SHIFT", "MoveTabRelative", -1, "swap-prev" },
	{ "PageDown", "CTRL|SHIFT", "MoveTabRelative", 1, "swap-next" },
}
for i = 1, 9 do
	for _, mods in ipairs({ "ALT", "SUPER" }) do
		expected_keys[#expected_keys + 1] = { tostring(i), mods, "ActivateTab", i - 1, "activate-" .. i }
	end
end
local keys = tabs.keys(opts)
assert(#keys == #expected_keys, "preserve all tab shortcuts")
for i, expected in ipairs(expected_keys) do
	local key = keys[i]
	assert(key.key == expected[1] and key.mods == expected[2], "preserve key/mods at " .. i)
	local value = key.action[expected[3]]
	if type(expected[4]) == "table" then
		assert(
			key.action.CloseCurrentTab and key.action.CloseCurrentTab.confirm == false,
			"preserve close confirmation behavior"
		)
	else
		assert(value == expected[4], "preserve action at " .. i)
	end
	assert(key.desc == expected[5], "description must match navigation direction: " .. key.key .. " " .. key.mods)
end
print("PASS all " .. #keys .. " tab key actions and corrected direction descriptions")
