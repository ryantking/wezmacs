--[[
  Module: workspace
  Category: workflows
  Description: Workspace switching and management with fuzzy search

  Provides:
  - Fuzzy workspace switcher via plugin
  - Create new workspace with name prompt
  - Delete workspace with fuzzy selection
  - Previous workspace navigation
  - System workspace quick access

  Configurable flags:
    leader_key - Workspace key (default: s)
    leader_mod - Leader modifier (default: LEADER)
]]

local wezterm = require("wezterm")
local act = wezterm.action
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local M = {}

M._NAME = "workspace"
M._CATEGORY = "workflows"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Workspace switching and management"
M._EXTERNAL_DEPS = { "smart_workspace_switcher (plugin)" }
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  leader_key = "s",
  leader_mod = "LEADER",
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

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
  -- Plugin setup
  workspace_switcher.apply_to_config(config)

  -- Keybindings
  config.keys = config.keys or {}

  -- Workspace switcher
  table.insert(config.keys, {
    key = state.config.leader_key,
    mods = state.config.leader_mod,
    action = workspace_switcher.switch_workspace(),
  })

  -- Switch to previous workspace
  table.insert(config.keys, {
    key = "S",
    mods = state.config.leader_mod,
    action = workspace_switcher.switch_to_prev_workspace(),
  })

  -- Jump to System workspace
  table.insert(config.keys, {
    key = "B",
    mods = state.config.leader_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(
        act.SwitchToWorkspace({
          name = "~/System",
          spawn = { cwd = wezterm.home_dir .. "/System" },
        }),
        pane
      )
      window:set_right_status(window:active_workspace())
    end),
  })

  -- Claude workspaces (only if claudectl available)
  local has_claudectl = wezterm.run_child_process({ "which", "claudectl" })
  if has_claudectl then
    -- Create claudectl workspace
    table.insert(config.keys, {
      key = "C",
      mods = state.config.leader_mod,
      action = wezterm.action_callback(create_claudectl_workspace),
    })

    -- List and select claudectl workspace
    table.insert(config.keys, {
      key = "c",
      mods = state.config.leader_mod,
      action = wezterm.action_callback(list_claudectl_sessions),
    })

    -- Delete claudectl workspace (using 'd' would conflict, use Delete key or similar)
    -- For now, skipping to avoid conflicts
  end

  -- Domain management (optional)
  table.insert(config.keys, { key = "a", mods = state.config.leader_mod, action = act.AttachDomain("unix") })
  table.insert(config.keys, { key = "d", mods = state.config.leader_mod, action = act.DetachDomain({ DomainName = "unix" }) })
end

return M
