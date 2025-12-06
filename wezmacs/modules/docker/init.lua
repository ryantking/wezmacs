--[[
  Module: docker
  Category: devops
  Description: Docker container management with lazydocker

  Provides:
  - lazydocker in smart split (LEADER d d)
  - lazydocker in new tab (LEADER d D)
  - Container, image, and volume management

  Configuration:
    leader_key - Key to activate docker menu (default: "d")
    leader_mod - Modifier for leader key (default: "LEADER")
]]

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.docker.actions")
local spec = require("wezmacs.modules.docker.spec")

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
