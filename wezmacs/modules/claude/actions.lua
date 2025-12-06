--[[
  Claude module actions
  All action callbacks and helper functions for claude module
]]

local wezterm = require("wezterm")
local act = wezterm.action
local action_lib = require("wezmacs.lib.actions")
local theme = require("wezmacs.lib.theme")

local M = {}

M.claude_smart_split = action_lib.smart_split_action("claude")

M.claude_new_tab = action_lib.new_tab_action("claude")

-- Create and open agentctl workspace
function M.create_agentctl_workspace(window, pane)
  -- Get color from theme library
  local prompt_color = theme.get_accent_color("#56be8d")

  window:perform_action(
    act.PromptInputLine({
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
          .. ')\" && claude'
        inner_window:perform_action(
          act.SpawnCommandInNewTab({
            args = { os.getenv("SHELL") or "/bin/bash", "-lc", cmd },
          }),
          inner_pane
        )
      end),
    }),
    pane
  )
end

-- List and select agentctl workspace
function M.list_agentctl_sessions(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir

  local success, output, stderr = wezterm.run_child_process({
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "cd " .. wezterm.shell_quote_arg(cwd) .. " && agentctl workspace list --json",
  })

  if not success or not output or output == "" then
    window:toast_notification("WezTerm", "No workspaces found", nil, 3000)
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
    window:toast_notification("WezTerm", "No valid branches found", nil, 3000)
    return
  end

  window:perform_action(
    act.InputSelector({
      title = "Select Workspace",
      choices = choices,
      fuzzy = true,
      fuzzy_description = "Filter: ",
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if id then
          local workspace_path_cmd = "cd "
            .. wezterm.shell_quote_arg(cwd)
            .. " && agentctl workspace show "
            .. wezterm.shell_quote_arg(id)
          local cmd_success, workspace_path = wezterm.run_child_process({
            os.getenv("SHELL") or "/bin/bash",
            "-lc",
            workspace_path_cmd,
          })
          if cmd_success and workspace_path then
            workspace_path = workspace_path:gsub("\n", ""):gsub("\r", "")
            inner_window:perform_action(
              act.SpawnCommandInNewTab({
                args = {
                  os.getenv("SHELL") or "/bin/bash",
                  "-lc",
                  "cd " .. wezterm.shell_quote_arg(workspace_path) .. " && claude",
                },
              }),
              inner_pane
            )
          else
            inner_window:toast_notification("WezTerm", "Failed to get workspace path", nil, 3000)
          end
        end
      end),
    }),
    pane
  )
end

-- Delete agentctl workspace
function M.delete_agentctl_session(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir

  local success, output, stderr = wezterm.run_child_process({
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "cd " .. wezterm.shell_quote_arg(cwd) .. " && agentctl workspace list --json",
  })

  if not success or not output or output == "" then
    window:toast_notification("WezTerm", "No workspaces found", nil, 3000)
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
    act.InputSelector({
      title = "Delete Workspace",
      choices = choices,
      fuzzy = true,
      fuzzy_description = "Filter: ",
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if id then
          local del_cmd = "cd "
            .. wezterm.shell_quote_arg(cwd)
            .. " && agentctl workspace delete "
            .. wezterm.shell_quote_arg(id)
          local del_success, del_stdout, del_stderr = wezterm.run_child_process({
            os.getenv("SHELL") or "/bin/bash",
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
end

return M
