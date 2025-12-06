--[[
  Module: git
  Category: integration
  Description: Lazygit integration with smart splitting and git utilities

  Provides:
  - Smart-split lazygit launcher (auto-orients based on window aspect ratio)
  - Git diff viewer (main branch comparison with delta formatting)
  - Key table for git operations (LEADER+g submenu)

  Configurable flags:
    leader_key - Git submenu key (default: g)
    leader_mod - Leader modifier (default: LEADER)
]]

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.git.actions")
local spec = require("wezmacs.modules.git.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  -- Apply keybindings using library
  keybindings.apply_keys(config, spec, actions)

  -- Any other git-specific config
  -- (none needed for this module)
end

return M
