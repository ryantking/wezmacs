--[[
  Module: file-manager
  Category: tools
  Description: File management with configurable terminal file manager

  Provides:
  - File manager in smart split (LEADER f f)
  - File manager in new tab (LEADER f F)
  - File manager with sudo in split (LEADER f s)
  - File manager with sudo in tab (LEADER f S)
  - Configurable file manager (default: yazi)

  Configuration:
    file_manager - File manager to use (default: "yazi")
    leader_key - Key to activate file-manager menu (default: "f")
    leader_mod - Modifier for leader key (default: "LEADER")
]]

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.file-manager.actions")
local spec = require("wezmacs.modules.file-manager.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  opts = opts or {}
  local mod = opts.file_manager ~= nil and opts or wezmacs.get_module(M._NAME)
  
  -- Setup actions with file manager config
  actions.setup(mod.file_manager)

  -- Apply keybindings using library
  keybindings.apply_keys(config, spec, actions)
end

return M
