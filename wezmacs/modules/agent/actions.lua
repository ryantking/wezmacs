--[[
  Agent Module Actions

  Custom action functions for agent workspace management.
]]

local wezterm = require("wezterm")
local wezmacs = require("wezmacs")

-- Theme helper function
local function get_accent_color(fallback)
	local color_scheme = wezmacs.color_scheme()
	if color_scheme and color_scheme.ansi and color_scheme.ansi[3] then
		return color_scheme.ansi[3]
	end

	return fallback or "#56be8d"
end

-- Create workspace action
local function create_workspace(agent)
	local prompt_color = get_accent_color("#56be8d")
	return wezterm.action_callback(function(window, pane)
		window:perform_action(
			wezterm.action.PromptInputLine({
				description = wezterm.format({
					{ Foreground = { Color = prompt_color } },
					{ Text = "Enter workspace name: " },
				}),
				action = wezterm.action_callback(function(inner_window, inner_pane, line)
					if not line or line == "" then
						return
					end
					local cwd_uri = pane:get_current_working_dir()
					local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
					local cmd = "cd "
						.. wezterm.shell_quote_arg(cwd)
						.. " && agentctl workspace create "
						.. wezterm.shell_quote_arg(line)
						.. ' && cd "$(cd '
						.. wezterm.shell_quote_arg(cwd)
						.. " && agentctl workspace show "
						.. wezterm.shell_quote_arg(line)
						.. ')" && '
						.. wezterm.shell_quote_arg(agent)
					inner_window:perform_action(
						wezterm.action.SpawnCommandInNewTab({
							args = { wezmacs.config.shell, "-lc", cmd },
						}),
						inner_pane
					)
				end),
			}),
			pane
		)
	end)
end

-- Open workspace action
local function open_workspace(agent)
	return wezterm.action_callback(function(window, pane)
		local cwd_uri = pane:get_current_working_dir()
		local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
		local success, output, stderr = wezterm.run_child_process({
			wezmacs.config.shell,
			"-lc",
			"cd " .. wezterm.shell_quote_arg(cwd) .. " && agentctl workspace list --json",
		})
		if not success then
			window:toast_notification("WezTerm", "Error listing workspaces: " .. output .. "\n" .. stderr, nil, 3000)
			return
		end
		local ok, workspaces = pcall(wezterm.json_parse, output)
		if not ok or not workspaces or #workspaces == 0 then
			window:toast_notification("WezTerm", "Unable to parse workspaces", nil, 3000)
			return
		end
		local choices = {}
		for _, ws in ipairs(workspaces) do
			if ws.branch then
				table.insert(choices, { id = ws.branch, label = ws.branch })
			end
		end
		if #choices == 0 then
			window:toast_notification("WezTerm", "No valid workspaces found", nil, 3000)
			return
		end
		window:perform_action(
			wezterm.action.InputSelector({
				title = "Select Workspace",
				choices = choices,
				fuzzy = true,
				fuzzy_description = "Filter: ",
				action = wezterm.action_callback(function(inner_window, inner_pane, id, _)
					if id then
						local workspace_path_cmd = "cd "
							.. wezterm.shell_quote_arg(cwd)
							.. " && agentctl workspace show "
							.. wezterm.shell_quote_arg(id)
						ok, output = wezterm.run_child_process({
							wezmacs.config.shell,
							"-lc",
							workspace_path_cmd,
						})
						if ok then
							local workspace_path = output:gsub("\n", ""):gsub("\r", "")
							inner_window:perform_action(
								wezterm.action.SpawnCommandInNewTab({
									args = {
										wezmacs.config.shell,
										"-lc",
										"cd " .. wezterm.shell_quote_arg(workspace_path) .. " && " .. wezterm.shell_quote_arg(agent),
									},
								}),
								inner_pane
							)
						else
							inner_window:toast_notification("WezTerm", "Failed to get workspace path: " .. output, nil, 3000)
						end
					end
				end),
			}),
			pane
		)
	end)
end

-- Delete workspace action
local delete_workspace = wezterm.action_callback(function(window, pane)
	local cwd_uri = pane:get_current_working_dir()
	local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
	local success, output, stderr = wezterm.run_child_process({
		wezmacs.config.shell,
		"-lc",
		"cd " .. wezterm.shell_quote_arg(cwd) .. " && agentctl workspace list --json",
	})
	if not success or not output or output == "" then
		window:toast_notification("WezTerm", "Error listing workspaces: " .. output .. "\n" .. stderr, nil, 3000)
		return
	end
	local ok, workspaces = pcall(wezterm.json_parse, output)
	if not ok or not workspaces or #workspaces == 0 then
		window:toast_notification("WezTerm", "No workspaces found", nil, 3000)
		return
	end
	local choices = {}
	for _, ws in ipairs(workspaces) do
		if ws.branch then
			table.insert(choices, { id = ws.branch, label = ws.branch })
		end
	end
	if #choices == 0 then
		window:toast_notification("WezTerm", "No workspaces found", nil, 3000)
		return
	end
	window:perform_action(
		wezterm.action.InputSelector({
			title = "Delete Workspace",
			choices = choices,
			fuzzy = true,
			fuzzy_description = "Filter: ",
			action = wezterm.action_callback(function(inner_window, _, id, label)
				if id then
					local del_cmd = "cd "
						.. wezterm.shell_quote_arg(cwd)
						.. " && agentctl workspace delete "
						.. wezterm.shell_quote_arg(id)
					local del_success, _, del_stderr = wezterm.run_child_process({
						wezmacs.config.shell,
						"-lc",
						del_cmd,
					})
					if del_success then
						inner_window:toast_notification("WezTerm", "Deleted workspace: " .. label, nil, 3000)
					else
						local error_msg = del_stderr and del_stderr:gsub("\n", " ") or "unknown error"
						inner_window:toast_notification("WezTerm", "Delete failed: " .. error_msg, nil, 5000)
					end
				end
			end),
		}),
		pane
	)
end)

return {
	CreateWorkspace = create_workspace,
	OpenWorkspace = open_workspace,
	DeleteWorkspace = delete_workspace,
}
