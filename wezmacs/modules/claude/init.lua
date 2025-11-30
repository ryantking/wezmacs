--[[
  Module: claude
  Category: workflows
  Description: Claude Code integration with workspace management

  Provides:
  - New Claude session in tab
  - Create new claudectl workspace
  - List and select active claudectl workspaces
  - Delete claudectl workspaces

  Note: This module depends on claudectl being installed.
  If not available, only basic claude launching works.

  Configurable flags:
    leader_key - Claude submenu key (default: c)
    leader_mod - Leader modifier (default: LEADER)
]]

local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

M._NAME = "claude"
M._CATEGORY = "workflows"
M._DESCRIPTION = "Claude Code integration and workspace management"
M._EXTERNAL_DEPS = { "claude (CLI)", "claudectl" }
M._FEATURES = {}
M._CONFIG_SCHEMA = {
  leader_key = "c",
  leader_mod = "LEADER",
}

-- Create and open claudectl workspace
local function create_claudectl_workspace(window, pane)
  window:perform_action(
    act.PromptInputLine({
      description = wezterm.format({
        { Foreground = { Color = "#56be8d" } },
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
          .. " && claudectl workspace create "
          .. wezterm.shell_quote_arg(line)
          .. ' && cd "$(cd '
          .. wezterm.shell_quote_arg(cwd)
          .. " && claudectl workspace show "
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

-- List and select claudectl workspace
local function list_claudectl_sessions(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir

  local success, output, stderr = wezterm.run_child_process({
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "cd " .. wezterm.shell_quote_arg(cwd) .. " && claudectl workspace list --json",
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
            .. " && claudectl workspace show "
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

-- Delete claudectl workspace
local function delete_claudectl_session(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir

  local success, output, stderr = wezterm.run_child_process({
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "cd " .. wezterm.shell_quote_arg(cwd) .. " && claudectl workspace list --json",
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
            .. " && claudectl workspace delete "
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

function M.apply_to_config(config, state)
  -- Create claude key table
  config.key_tables = config.key_tables or {}
  config.key_tables.claude = {
    { key = "c", action = act.SpawnCommandInNewTab({ args = { "fish", "-c", "claude" } }) },
    { key = "C", action = wezterm.action_callback(create_claudectl_workspace) },
    { key = "s", action = wezterm.action_callback(list_claudectl_sessions) },
    { key = "d", action = wezterm.action_callback(delete_claudectl_session) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate claude menu
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = state.config.leader_key,
    mods = state.config.leader_mod,
    action = act.ActivateKeyTable({
      name = "claude",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
