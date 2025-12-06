--[[
  Module: system-monitor
  Category: tools
  Description: System monitoring with bottom (btm)

  Provides:
  - bottom launcher in new tab
  - CPU, memory, disk, network monitoring

  Configurable flags:
    keybinding - Keybinding to launch btm (default: "h")
    modifier - Key modifier (default: "LEADER")
]]

local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.system-monitor.actions")
local spec = require("wezmacs.modules.system-monitor.spec")

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
