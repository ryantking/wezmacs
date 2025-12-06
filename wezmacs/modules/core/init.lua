--[[
  Module: core
  Category: system
  Description: Core WezTerm settings and global event handlers

  Provides:
  - Terminal protocol support (Kitty keyboard/graphics)
  - Shell and workspace defaults
  - Global event handlers
  - Framework initialization settings

  Configuration:
    enable_kitty_keyboard - Enable Kitty keyboard protocol (default: false)
    enable_kitty_graphics - Enable Kitty graphics protocol (default: true)
    default_prog - Default shell program (nil = use WezTerm default)
    default_workspace - Default workspace name (default: "~")

  Note: This module is always applied FIRST before all other modules.
]]

local wezterm = require("wezterm")
local spec = require("wezmacs.modules.core.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  opts = opts or {}
  local mod = opts.default_prog ~= nil and opts or wezmacs.get_module(M._NAME)

  -- Terminal protocol support
  config.enable_kitty_keyboard = mod.enable_kitty_keyboard
  config.enable_kitty_graphics = mod.enable_kitty_graphics

  -- Shell and workspace defaults
  if mod.default_prog then
    config.default_prog = mod.default_prog
  end

  -- Global event handlers
  wezterm.on("mux-is-process-stateful", function(_proc)
    return false
  end)
end

return M
