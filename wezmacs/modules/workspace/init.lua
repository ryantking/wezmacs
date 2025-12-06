--[[
  Module: workspace
  Category: workflows
  Description: WezTerm workspace switching and management with fuzzy search

  Provides:
  - Fuzzy workspace switcher (default: LEADER s)
  - Previous workspace navigation (default: LEADER S)
  - Integration with smart_workspace_switcher plugin

  Note: For Claude Code workspace management, see the claude module.

  Configuration:
    switch_key - Key for workspace switcher (default: "s")
    switch_mod - Modifier for switch key (default: "LEADER")
    prev_key - Key for previous workspace (default: "S")
    prev_mod - Modifier for previous key (default: "LEADER")
]]

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.workspace.actions")
local spec = require("wezmacs.modules.workspace.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  opts = opts or {}
  local mod = opts.default_workspace ~= nil and opts or wezmacs.get_module(M._NAME)
  
  config.default_workspace = mod.default_workspace

  -- Apply keybindings using library
  keybindings.apply_keys(config, spec, actions)
end

return M
