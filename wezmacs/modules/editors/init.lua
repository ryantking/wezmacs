--[[
  Module: editors
  Category: development
  Description: External code editor launchers (terminal editor and IDE)

  Provides:
  - Terminal editor in smart split (LEADER e t)
  - Terminal editor in new tab (LEADER e T)
  - IDE launcher in CWD (LEADER e i)
  - Configurable editor/IDE choices

  Configuration:
    terminal_editor - Terminal editor to use (default: "vim")
    ide - IDE to launch (default: "code" for VS Code)
    leader_key - Key to activate editors menu (default: "e")
    leader_mod - Modifier for leader key (default: "LEADER")
]]

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.editors.actions")
local spec = require("wezmacs.modules.editors.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  opts = opts or {}
  local mod = opts.editor ~= nil and opts or wezmacs.get_module(M._NAME)
  
  -- Setup actions with editor/ide config
  actions.setup(mod.editor, mod.ide)

  -- Apply keybindings using library
  keybindings.apply_keys(config, spec, actions)
end

return M
