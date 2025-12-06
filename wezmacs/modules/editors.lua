--[[
  Module: editors
  Category: development
  Description: External code editor launchers (terminal editor and IDE)
]]

local keybindings = require("wezmacs.lib.keybindings")
local action_lib = require("wezmacs.lib.actions")
local wezterm = require("wezterm")

-- Actions (inline) - these will be set up with config values
local _editor = "vim"
local _ide = "code"
local actions = {
  terminal_smart_split = function(window, pane)
    return action_lib.smart_split_action(_editor)(window, pane)
  end,
  terminal_new_tab = function(window, pane)
    return action_lib.new_tab_action(_editor)
  end,
  launch_ide = function(window, pane)
    local cwd_uri = pane:get_current_working_dir()
    local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
    wezterm.background_child_process({ _ide, cwd })
  end,
}

-- Module spec (LazyVim-style inline spec)
return {
  name = "editors",
  category = "development",
  description = "External code editor launchers",

  dependencies = {
    external = {},
    modules = { "keybindings" },
  },

  opts = {
    editor = "vim",
    ide = "code",
    editor_split_key = "e",
    editor_tab_key = "E",
    ide_key = "i",
  },

  keys = {
    {
      key = "e",
      mods = "LEADER",
      action = actions.terminal_smart_split,
    },
    {
      key = "E",
      mods = "LEADER",
      action = actions.terminal_new_tab,
    },
    {
      key = "i",
      mods = "LEADER",
      action = actions.launch_ide,
    },
  },

  enabled = true,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.editor ~= nil and opts or wezmacs.get_module("editors")
    
    -- Update action closures with config values
    _editor = mod.editor
    _ide = mod.ide

    -- Get spec (self-reference via closure)
    local spec = require("wezmacs.modules.editors")
    -- Apply keybindings using library
    keybindings.apply_keys(config, spec)
  end,
}
