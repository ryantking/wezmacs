--[[
  Module: docker
  Category: devops
  Description: Docker container management with lazydocker

  Provides:
  - lazydocker launcher in new tab
  - Container, image, and volume management

  Configurable flags:
    keybinding - Keybinding to launch lazydocker (default: "D")
    modifier - Key modifier (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M._NAME = "docker"
M._CATEGORY = "devops"
M._DESCRIPTION = "Docker container management with lazydocker"
M._EXTERNAL_DEPS = { "lazydocker" }
M._FEATURES = {}
M._CONFIG_SCHEMA = {
  leader_key = "d",
  leader_mod = "LEADER",
}

function M.apply_to_config(wezterm_config)
  local mod_config = wezmacs.get_config(M._NAME)
  local split = require("wezmacs.utils.split")

  -- Lazydocker in smart split
  local function lazydocker_split(window, pane)
    split.smart_split(pane, { "lazydocker" })
  end

  -- Create docker key table
  wezterm_config.key_tables = wezterm_config.key_tables or {}
  wezterm_config.key_tables.docker = {
    { key = "d", action = wezterm.action_callback(lazydocker_split) },
    { key = "D", action = act.SpawnCommandInNewTab({ args = { "lazydocker" } }) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate docker menu
  wezterm_config.keys = wezterm_config.keys or {}
  table.insert(wezterm_config.keys, {
    key = mod_config.leader_key,
    mods = mod_config.leader_mod,
    action = act.ActivateKeyTable({
      name = "docker",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
