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
M._VERSION = "0.1.0"
M._DESCRIPTION = "Git workflow integration (lazygit, diff, etc)"
M._EXTERNAL_DEPS = { "lazygit", "git", "delta" }
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  leader_key = "g",
  leader_mod = "LEADER",
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

-- Lazygit in smart split (auto-orientation based on window aspect ratio)
local function lazygit_smart_split(window, pane)
  local dims = pane:get_dimensions()
  local direction = dims.pixel_height > dims.pixel_width and "Bottom" or "Right"
  pane:split({
    direction = direction,
    size = 0.5,
    args = { "lazygit", "-sm", "half" },
  })
end

-- Git diff with smart split orientation
local function git_diff_smart_split(window, pane)
  local dims = pane:get_dimensions()
  local direction = dims.pixel_height > dims.pixel_width and "Bottom" or "Right"
  pane:split({
    direction = direction,
    size = 0.5,
    args = {
      os.getenv("SHELL") or "/bin/bash",
      "-lc",
      "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status",
    },
  })
end

-- Git diff in new window
local git_diff_new_window = act.SpawnCommandInNewWindow({
  args = {
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status",
  },
})

function M.apply_to_config(config, state)
  -- Create git key table
  config.key_tables = config.key_tables or {}
  config.key_tables.git = {
    { key = "g", action = wezterm.action_callback(lazygit_smart_split) },
    { key = "G", action = act.SpawnCommandInNewTab({ args = { "lazygit" } }) },
    { key = "d", action = wezterm.action_callback(git_diff_smart_split) },
    { key = "D", action = git_diff_new_window },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate git menu
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = state.config.leader_key,
    mods = state.config.leader_mod,
    action = act.ActivateKeyTable({
      name = "git",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
