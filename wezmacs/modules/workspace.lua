--[[
  Module: workspace
  Category: workflows
  Description: WezTerm workspace switching and management with fuzzy search
]]

local keybindings = require("wezmacs.lib.keybindings")
local wezterm = require("wezterm")

-- Actions (inline)
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local actions = {
  switch_workspace = function(window, pane)
    return workspace_switcher.switch_workspace()
  end,
  switch_to_prev_workspace = function(window, pane)
    return workspace_switcher.switch_to_prev_workspace()
  end,
}

-- Module spec (LazyVim-style inline spec)
return {
  name = "workspace",
  category = "workflows",
  description = "Workspace switching and management",

  dependencies = {
    external = {},
    modules = {},
  },

  opts = {
    default_workspace = "~",
    switch_key = "s",
    switch_mod = "LEADER",
    prev_key = "S",
    prev_mod = "LEADER",
  },

  keys = {
    {
      key = "s",
      mods = "LEADER",
      action = actions.switch_workspace,
    },
    {
      key = "S",
      mods = "LEADER",
      action = actions.switch_to_prev_workspace,
    },
  },

  enabled = true,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.default_workspace ~= nil and opts or wezmacs.get_module("workspace")
    
    config.default_workspace = mod.default_workspace

    -- Get spec (self-reference via closure)
    local spec = require("wezmacs.modules.workspace")
    -- Apply keybindings using library
    keybindings.apply_keys(config, spec)
  end,
}
