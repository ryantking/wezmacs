-- Snapshot-only tab labels. OSC and explicit titles are content, not commands.
local wezterm = require("wezterm")
local M = {}

local fonts = wezterm.nerdfonts or {}
local app_labels = {
	curl = (fonts.cod_globe and fonts.cod_globe .. " " or "") .. "curl",
	wget = (fonts.md_arrow_down_box and fonts.md_arrow_down_box .. " " or "") .. "wget",
	nvim = "Neovim",
	claude = "Claude",
	codex = "Codex",
	opencode = "OpenCode",
	hermes = "Hermes",
}

local shells = {
	bash = true,
	zsh = true,
	fish = true,
	sh = true,
	dash = true,
	nu = true,
	pwsh = true,
	powershell = true,
	cmd = true,
}

local function nonempty(value) return type(value) == "string" and value ~= "" end

local function cwd_label(cwd)
	local path = cwd and cwd.file_path
	if not nonempty(path) then
		return nil
	end
	path = path:gsub("\\", "/")
	local normalized = path:gsub("/+$", "")
	local home = (wezterm.home_dir or ""):gsub("\\", "/"):gsub("/+$", "")
	if normalized == "" then
		return "/"
	elseif normalized == home then
		return "~"
	elseif normalized:match("^%a:$") then
		return normalized .. "/"
	end
	return normalized:match("([^/]+)$") or "Shell"
end

local function executable_label(executable, pane)
	local name = executable:lower():gsub("%.exe$", "")
	if shells[name] then
		return cwd_label(pane.current_working_dir) or executable
	elseif app_labels[name] then
		local cwd = cwd_label(pane.current_working_dir)
		return app_labels[name] .. (cwd and " · " .. cwd or "")
	end
	return executable
end

local function title_for(tab)
	if nonempty(tab.tab_title) then
		return tab.tab_title
	end
	local pane = tab.active_pane or {}
	if nonempty(pane.title) then
		-- Only exact known executable names are defaults; never parse task/buffer titles.
		return executable_label(pane.title, pane)
	end
	local process = pane.foreground_process_name
	local executable = nonempty(process) and process:match("([^/\\]+)$")
	if executable then
		return executable_label(executable, pane)
	end
	return cwd_label(pane.current_working_dir) or "Shell"
end

function M.format_tab_title(tab, _, _, config, _, max_width)
	local pane = tab.active_pane or {}
	local zoomed, unseen = pane.is_zoomed, pane.has_unseen_output
	for _, item in ipairs(tab.panes or {}) do
		zoomed = zoomed or item.is_zoomed
		unseen = unseen or item.has_unseen_output
	end
	local prefix = " " .. tostring((tab.tab_index or 0) + 1) .. " "
	local suffix = (zoomed and " [Z]" or "") .. " "
	local marker = unseen and not tab.is_active and "· " or ""
	local title = title_for(tab)
	local main = prefix .. title .. suffix
	-- max_width is a cell budget only for the retro bar. Fancy clips natively.
	if config and config.use_fancy_tab_bar == false then
		local width = math.max(0, max_width or config.tab_max_width or 32)
		local available = math.max(0, width - wezterm.column_width(prefix .. suffix .. marker))
		title = wezterm.truncate_right(title, available)
		main = wezterm.truncate_right(prefix .. title .. suffix, math.max(0, width - wezterm.column_width(marker)))
		marker = wezterm.truncate_right(marker, math.max(0, width - wezterm.column_width(main)))
	end
	local result = { { Text = main } }
	if marker ~= "" then
		local colors = config and config.colors
		local color = colors and colors.ansi and colors.ansi[5]
		if color then
			result[#result + 1] = { Foreground = { Color = color } }
		end
		result[#result + 1] = { Text = marker }
	end
	return result
end

return M
