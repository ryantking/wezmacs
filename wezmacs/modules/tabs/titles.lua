--[[
  Tabs title formatting
  Handles extracting and formatting tab titles with icons and context
]]

local wezterm = require("wezterm")
local M = {}

-- Icons to prepend to titles
M.icons = {
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
M.titles = {
	["k9s"] = wezterm.nerdfonts.dev_kubernetes .. " Kubernetes",
	["lazydocker"] = wezterm.nerdfonts.md_docker .. " Docker",
	["spotify_player"] = wezterm.nerdfonts.md_spotify .. " Spotify",
	["btm"] = wezterm.nerdfonts.md_chart_donut_variant .. " Bottom",
	["htop"] = wezterm.nerdfonts.md_chart_areaspline .. " Top",
	["btop"] = wezterm.nerdfonts.md_chart_areaspline .. " Btop",
}

-- Extract and format tab title with icon and context
function M.format(tab, max_width)
	local title = (tab.tab_title and #tab.tab_title > 0) and tab.tab_title or tab.active_pane.title
	local bin, other = title:match("^(%S+)%s*%-?%s*%s*(.*)$")

	-- Full title replacement (icon + custom text, ignore application title)
	if M.titles[bin] then
		title = M.titles[bin]
	-- Icon prepending (icon + application's title, or working directory if no title)
	elseif M.icons[bin] then
		local use_content = false

		-- If application provided context/title, prepend icon to it
		if other and other ~= "" then
			-- Strip directory path from end (shell adds this, we don't want it for commands)
			local content = other:gsub("%s+[~/][^%s]*$", ""):gsub("%s+~$", "")

			-- If we still have content after stripping the path, use it
			if content ~= "" then
				title = M.icons[bin] .. " " .. content
				use_content = true
			end
		end

		-- Fallback to working directory if no content
		if not use_content then
			local pane = tab.active_pane
			local cwd_context = "~" -- default
			if pane.current_working_dir then
				local cwd = pane.current_working_dir.file_path or ""
				-- Normalize path by removing trailing slash
				local cwd_normalized = cwd:gsub("/$", "")
				local home_normalized = wezterm.home_dir:gsub("/$", "")

				-- Show ~ for home directory, otherwise show directory name
				if cwd_normalized == home_normalized or cwd_normalized == "" then
					cwd_context = "~"
				else
					local dir_name = cwd_normalized:match("([^/]+)$") or ""
					if dir_name ~= "" then
						cwd_context = dir_name
					end
				end
			end
			title = M.icons[bin] .. " " .. cwd_context
		end
	end

	-- Show zoom indicator if pane is zoomed
	local is_zoomed = false
	for _, pane in ipairs(tab.panes) do
		if pane.is_zoomed then
			is_zoomed = true
			break
		end
	end
	if is_zoomed then
		title = "🔍 " .. title
	end

	-- Don't truncate here - tab_max_width config handles it
	return " " .. title .. " "
end

return M
