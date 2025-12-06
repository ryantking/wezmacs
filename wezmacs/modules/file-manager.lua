--[[
  Module: file-manager
  Category: tools
  Description: File management with configurable terminal file manager
]]

local keybindings = require("wezmacs.lib.keybindings")
local action_lib = require("wezmacs.lib.actions")

-- Actions (inline) - these will be set up with config values
local _file_manager = "yazi"
local actions = {
  file_manager_split = function(window, pane)
    return action_lib.smart_split_action(_file_manager)(window, pane)
  end,
  file_manager_new_tab = function(window, pane)
    return action_lib.new_tab_action(_file_manager)
  end,
  file_manager_sudo_split = function(window, pane)
    return action_lib.smart_split_action("sudo " .. _file_manager .. " /")(window, pane)
  end,
  file_manager_sudo_tab = function(window, pane)
    return action_lib.new_tab_action("sudo " .. _file_manager .. " /")
  end,
}

-- Module spec (LazyVim-style inline spec)
return {
  name = "file-manager",
  category = "tools",
  description = "File management with yazi terminal file manager",

  dependencies = {
    external = { "yazi" },
    modules = { "keybindings" },
  },

  opts = {
    file_manager = "yazi",
    leader_key = "f",
    leader_mod = "LEADER",
  },

  keys = {
    {
      leader = "f",
      submenu = "file-manager",
      bindings = {
        { key = "f", desc = "File manager in split", action = actions.file_manager_split },
        { key = "F", desc = "File manager in new tab", action = actions.file_manager_new_tab },
        { key = "s", desc = "File manager with sudo in split", action = actions.file_manager_sudo_split },
        { key = "S", desc = "File manager with sudo in tab", action = actions.file_manager_sudo_tab },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("yazi")
  end,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.file_manager ~= nil and opts or wezmacs.get_module("file-manager")
    
    -- Update action closures with config values
    _file_manager = mod.file_manager

    -- Get spec (self-reference via closure)
    local spec = require("wezmacs.modules.file-manager")
    -- Apply keybindings using library
    keybindings.apply_keys(config, spec)
  end,
}
