--[[
  Module: git
  Category: workflows
  Description: Git workflow integration (lazygit, diff viewing, branch management)

  Provides:
  - Smart-split lazygit launcher (auto-orients based on window aspect ratio)
  - Git diff viewer (main branch comparison with delta formatting)
  - Key table for git operations (LEADER+g submenu)

  Configurable flags:
    leader_key - Git submenu key (default: g)
    leader_mod - Leader modifier (default: LEADER)
]]

local wezterm = require("wezterm")
local act = wezterm.action
local actions = require("wezmacs.modules.git.actions")

local M = {}

M._NAME = "git"
M._CATEGORY = "workflows"
M._DESCRIPTION = "Git workflow integration (lazygit, diff, etc)"
M._EXTERNAL_DEPS = { "lazygit", "git", "delta" }
M._CONFIG = {
  leader_key = "g",
  leader_mod = "LEADER",
}

-- Git diff in new window
local git_diff_new_window = act.SpawnCommandInNewWindow({
  args = {
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status",
  },
})

function M.apply_to_config(config)
  local mod = wezmacs.get_module(M._NAME)

  -- Create git key table
  config.key_tables = config.key_tables or {}
  config.key_tables.git = {
    { key = "g", action = wezterm.action_callback(actions.lazygit_smart_split) },
    { key = "G", action = act.SpawnCommandInNewTab({ args = { "lazygit" } }) },
    { key = "d", action = wezterm.action_callback(actions.git_diff_smart_split) },
    { key = "D", action = git_diff_new_window },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add riff binding if enabled
  if mod.riff and mod.riff.enabled then
    table.insert(config.key_tables.git, { key = "r", action = wezterm.action_callback(actions.riff_smart_split) })
  end

  -- Add keybinding to activate git menu
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = mod.leader_key,
    mods = mod.leader_mod,
    action = act.ActivateKeyTable({
      name = "git",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
