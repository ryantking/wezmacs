--[[
  Module: docker
  Category: devops
  Description: Docker container management with lazydocker
]]

local keybindings = require("wezmacs.lib.keybindings")
local action_lib = require("wezmacs.lib.actions")

-- Actions (inline)
local actions = {
  lazydocker_split = action_lib.smart_split_action("lazydocker"),
  lazydocker_new_tab = action_lib.new_tab_action("lazydocker"),
}

-- Module spec (LazyVim-style inline spec)
return {
  name = "docker",
  category = "devops",
  description = "Docker container management with lazydocker",

  dependencies = {
    external = { "lazydocker" },
    modules = { "keybindings" },
  },

  opts = {
    leader_key = "d",
    leader_mod = "LEADER",
  },

  keys = {
    {
      leader = "d",
      submenu = "docker",
      bindings = {
        { key = "d", desc = "Lazydocker in split", action = actions.lazydocker_split },
        { key = "D", desc = "Lazydocker in new tab", action = actions.lazydocker_new_tab },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("lazydocker")
  end,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    local spec = require("wezmacs.modules.docker")
    -- Apply keybindings using library
    keybindings.apply_keys(config, spec)
  end,
}
