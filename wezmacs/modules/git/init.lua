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
local M = {}

M._NAME = "git"
M._CATEGORY = "workflows"
M._DESCRIPTION = "Git workflow integration (lazygit, diff, etc)"
M._EXTERNAL_DEPS = { "lazygit", "git", "delta" }
M._CONFIG = {
  leader_key = "g",
  leader_mod = "LEADER",
  riff = {
    enabled = false,
    config = {},
    deps = { "riff" },
  },
}

local split = require("wezmacs.utils.split")

-- Lazygit in smart split (auto-orientation based on window aspect ratio)
local function lazygit_smart_split(window, pane)
  split.smart_split(pane, { "lazygit", "-sm", "half" })
end

-- Git diff with smart split orientation
local function git_diff_smart_split(window, pane)
  split.smart_split(pane, {
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status",
  })
end

-- Riff in smart split (if enabled)
local function riff_smart_split(window, pane)
  split.smart_split(pane, { "riff" })
end

-- Git diff in new window
local git_diff_new_window = act.SpawnCommandInNewWindow({
  args = {
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status",
  },
})

function M.apply_to_config(config)
  local mod_config = wezmacs.get_config(M._NAME)
  local enabled_flags = wezmacs.get_enabled_flags(M._NAME)

  -- Check if riff flag is enabled
  local riff_enabled = false
  for _, flag in ipairs(enabled_flags) do
    if flag == "riff" then
      riff_enabled = true
      break
    end
  end

  -- Create git key table
  config.key_tables = config.key_tables or {}
  config.key_tables.git = {
    { key = "g", action = wezterm.action_callback(lazygit_smart_split) },
    { key = "G", action = act.SpawnCommandInNewTab({ args = { "lazygit" } }) },
    { key = "d", action = wezterm.action_callback(git_diff_smart_split) },
    { key = "D", action = git_diff_new_window },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add riff binding if enabled
  if riff_enabled then
    table.insert(config.key_tables.git, { key = "r", action = wezterm.action_callback(riff_smart_split) })
  end

  -- Add keybinding to activate git menu
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = mod_config.leader_key,
    mods = mod_config.leader_mod,
    action = act.ActivateKeyTable({
      name = "git",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
