--[[
  Module: kubernetes
  Category: devops
  Description: Kubernetes cluster management with k9s
]]

local keybindings = require("wezmacs.lib.keybindings")
local action_lib = require("wezmacs.lib.actions")

-- Actions (inline)
local actions = {
  launch_k9s = action_lib.new_tab_action("k9s"),
}

-- Module spec (LazyVim-style inline spec)
return {
  name = "kubernetes",
  category = "devops",
  description = "Kubernetes cluster management with k9s",

  dependencies = {
    external = { "k9s" },
    modules = { "keybindings" },
  },

  opts = {
    keybinding = "k",
    modifier = "LEADER",
  },

  keys = {
    {
      key = "k",
      mods = "LEADER",
      action = actions.launch_k9s,
    },
  },

  enabled = function(ctx)
    return ctx.has_command("k9s")
  end,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    -- Get spec (self-reference via closure)
    local spec = require("wezmacs.modules.kubernetes")
    -- Apply keybindings using library
    keybindings.apply_keys(config, spec)
  end,
}
