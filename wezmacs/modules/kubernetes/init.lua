--[[
  Module: kubernetes
  Category: devops
  Description: Kubernetes cluster management with k9s

  Provides:
  - k9s launcher in new tab
  - Cluster management and monitoring

  Configurable flags:
    keybinding - Keybinding to launch k9s (default: "k")
    modifier - Key modifier (default: "LEADER")
]]

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.kubernetes.actions")
local spec = require("wezmacs.modules.kubernetes.spec")

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
