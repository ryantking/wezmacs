--[[
  Module: claude
  Category: workflows
  Description: Claude Code integration with workspace management

  Provides:
  - Open Claude in new tab (LEADER c c or LEADER c C)
  - Create new agentctl workspace (LEADER c w)
  - Switch to existing workspace (LEADER c s)
  - Delete agentctl workspace (LEADER c d)

  Note: This module depends on agentctl being installed.
  If not available, only basic claude launching works.

  Configuration:
    leader_key - Key to activate claude menu (default: "c")
    leader_mod - Modifier for leader key (default: "LEADER")
]]

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.claude.actions")
local spec = require("wezmacs.modules.claude.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  -- Apply keybindings using library
  keybindings.apply_keys(config, spec, actions)
end

return M
