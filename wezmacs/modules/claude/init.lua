--[[
  Module: claude
  Category: workflows
  Description: Claude Code integration with workspace management
]]

local wezmacs = require("wezmacs")
local act = wezmacs.action
local wezterm = require("wezterm")

-- Theme helper function
local function get_accent_color(fallback)
  if wezmacs.config and wezmacs.config.color_scheme then
    local scheme = wezterm.get_builtin_color_schemes()[wezmacs.config.color_scheme]
    if scheme and scheme.ansi and scheme.ansi[3] then
      return scheme.ansi[3]
    end
  end
  return fallback or "#56be8d"
end

return {
  name = "claude",
  category = "workflows",
  description = "Claude Code integration and workspace management",

  deps = { "claude", "agentctl" },

  opts = function()
    return {
      leader_key = "c",
      leader_mod = "LEADER",
    }
  end,

  keys = {
    LEADER = {
      c = {
        c = { action = act.SmartSplit("claude"), desc = "claude/claude-split" },
        C = { action = act.NewTab("claude"), desc = "claude/claude-tab" },
        w = {
          action = function(window, pane)
            local prompt_color = get_accent_color("#56be8d")
            window:perform_action(
              term.PromptInputLine({
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
                    term.SpawnCommandInNewTab({
                      args = { wezmacs.config.shell, "-lc", cmd },
                    }),
                    inner_pane
                  )
                end),
              }),
              pane
            )
          end,
          desc = "claude/create-workspace",
        },
        ["Space"] = {
          action = function(window, pane)
            local cwd_uri = pane:get_current_working_dir()
            local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
            local success, output, stderr = wezterm.run_child_process({
              wezmacs.config.shell,
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
              term.InputSelector({
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
                      wezmacs.config.shell,
                      "-lc",
                      workspace_path_cmd,
                    })
                    if cmd_success and workspace_path then
                      workspace_path = workspace_path:gsub("\n", ""):gsub("\r", "")
                      inner_window:perform_action(
                        term.SpawnCommandInNewTab({
                          args = {
                            wezmacs.config.shell,
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
          end,
          desc = "claude/list-workspaces",
        },
        s = {
          action = function(window, pane)
            local cwd_uri = pane:get_current_working_dir()
            local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
            local success, output, stderr = wezterm.run_child_process({
              wezmacs.config.shell,
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
              term.InputSelector({
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
                      wezmacs.config.shell,
                      "-lc",
                      workspace_path_cmd,
                    })
                    if cmd_success and workspace_path then
                      workspace_path = workspace_path:gsub("\n", ""):gsub("\r", "")
                      inner_window:perform_action(
                        term.SpawnCommandInNewTab({
                          args = {
                            wezmacs.config.shell,
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
          end,
          desc = "claude/switch-workspace",
        },
        d = {
          action = function(window, pane)
            local cwd_uri = pane:get_current_working_dir()
            local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
            local success, output, stderr = wezterm.run_child_process({
              wezmacs.config.shell,
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
              term.InputSelector({
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
          end,
          desc = "claude/delete-workspace",
        },
      },
    },
    SHIFT = {
      Enter = {
        action = function()
          return term.SendString("\x1b\r")
        end,
        desc = "claude/send-enter",
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("claude")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Module-specific setup (if any)
  end,
}
