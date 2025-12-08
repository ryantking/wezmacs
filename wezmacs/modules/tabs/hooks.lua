--[[
  Tabs title formatting
  Handles extracting and formatting tab titles with icons and context
]]

local wezterm = require("wezterm")
local M = {}

-- Icons to prepend to titles
local icons = {
	["bash"] = wezterm.nerdfonts.cod_terminal_bash,
	["fish"] = wezterm.nerdfonts.md_fish,
	["zsh"] = wezterm.nerdfonts.dev_terminal,
	["hx"] = wezterm.nerdfonts.md_dna,
	["nvim"] = wezterm.nerdfonts.custom_vim,
	["vim"] = wezterm.nerdfonts.dev_vim,
	["lazygit"] = wezterm.nerdfonts.md_git,
	["git"] = wezterm.nerdfonts.dev_git,
	["broot"] = wezterm.nerdfonts.md_folder,
	["yazi"] = wezterm.nerdfonts.md_folder,
	["cargo"] = wezterm.nerdfonts.dev_rust,
	["go"] = wezterm.nerdfonts.seti_go,
	["lua"] = wezterm.nerdfonts.seti_lua,
	["make"] = wezterm.nerdfonts.seti_makefile,
	["just"] = wezterm.nerdfonts.md_lightning_bolt,
	["python"] = wezterm.nerdfonts.dev_python,
	["python3"] = wezterm.nerdfonts.dev_python,
	["pip"] = wezterm.nerdfonts.dev_python,
	["uv"] = wezterm.nerdfonts.dev_python,
	["node"] = wezterm.nerdfonts.md_hexagon,
	["ruby"] = wezterm.nerdfonts.cod_ruby,
	["docker"] = wezterm.nerdfonts.md_docker,
	["brew"] = wezterm.nerdfonts.md_beer,
	["kubectl"] = wezterm.nerdfonts.dev_kubernetes,
	["curl"] = wezterm.nerdfonts.mdi_flattr,
	["wget"] = wezterm.nerdfonts.mdi_arrow_down_box,
	["gh"] = wezterm.nerdfonts.dev_github_badge,
	["psql"] = wezterm.nerdfonts.dev_postgresql,
	["sudo"] = wezterm.nerdfonts.fa_hashtag,
}

-- Full titles to replace applications
local titles = {
	["k9s"] = wezterm.nerdfonts.dev_kubernetes .. " Kubernetes",
	["lazydocker"] = wezterm.nerdfonts.md_docker .. " Docker",
	["spotify_player"] = wezterm.nerdfonts.md_spotify .. " Spotify",
	["btm"] = wezterm.nerdfonts.md_chart_donut_variant .. " Bottom",
	["htop"] = wezterm.nerdfonts.md_chart_areaspline .. " Top",
	["btop"] = wezterm.nerdfonts.md_chart_areaspline .. " Btop",
}

-- Add zoom annotation if pane zoomed
local function wrap_title(tab, title)
	for _, pane in ipairs(tab.panes) do
		if pane.is_zoomed then
			return { { Text = " 🔍 " .. title .. " " } }
		end
	end

	return { { Text = " " .. title .. " " } }
end

-- Extract and format tab title with icon and context
function M.format_tab_title(tab, _, _, _, _, _)
	-- Full title replacement (icon + custom text, ignore application title)
	local title = (tab.tab_title and #tab.tab_title > 0) and tab.tab_title or tab.active_pane.title
	if titles[title] then
		return wrap_title(tab, titles[title])
	end

	-- Icon prepending (icon + application's title, or working directory if no title)
	local bin, other = title:match("^(%S+)%s*%-?%s*%s*(.*)$")
	if not bin or #bin == 0 then
		local info = tab.active_pane.foreground_process_name
		bin = string.gsub(info, "(.*[/\\])(.*)", "%2")
	end

	if icons[bin] then
		local icon = icons[bin]
		if other and #other > 0 then
			return wrap_title(tab, icon .. " " .. other)
		end

		local pane = tab.active_pane
		if pane.current_working_dir then
			local cwd = pane.current_working_dir.file_path or ""
			-- Normalize path by removing trailing slash
			local cwd_normalized = cwd:gsub("/$", "")
			local home_normalized = wezterm.home_dir:gsub("/$", "")

			-- Show ~ for home directory
			if cwd_normalized == home_normalized or cwd_normalized == "" then
				return wrap_title(tab, icon .. "  ~")
			end

			-- Show directory name otherwise
			local dir_name = cwd_normalized:match("([^/]+)$") or ""
			if dir_name ~= "" then
				return wrap_title(tab, icon .. " " .. dir_name)
			end

			return wrap_title(tab, icon .. " ???")
		end
	end

	return wrap_title(tab, title)
end

return M
