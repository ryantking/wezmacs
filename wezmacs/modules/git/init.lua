--[[
  Module: git
  Description: Lazygit integration with smart splitting and git utilities
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
  name = "git",
  description = "Lazygit integration with smart splitting and git utilities",

  deps = { "lazygit", "delta", "git", "broot" },

  opts = {
    diff_branches = { "main", "master", "origin/main", "origin/master" },
  },

  keys = function(opts)
    local diff_cmds = {}
    for i, branch in ipairs(opts.diff_branches) do
      diff_cmds[i] = ("git diff %s 2>/dev/null"):format(branch)
    end
    table.insert(diff_cmds, "git diff")
    local diff_cmd = table.concat(diff_cmds, " || ")

    return {
      LEADER = {
        g = {
          {
            key = "g",
            action = wezmacs.action.SmartSplit("lazygit -sm half"),
            desc = "lazygit/split",
          },
          { key = "G", action = wezmacs.action.NewTab("lazygit"), desc = "lazygit/tab" },
          { key = "s", action = wezmacs.action.SmartSplit("br -ghc :gs"), desc = "status/split" },
          { key = "S", action = wezmacs.action.NewTab("br -ghc :gs"), desc = "status/tab" },
          { key = "d", action = wezmacs.action.SmartSplit(diff_cmd), desc = "diff/split" },
          { key = "D", action = wezmacs.action.NewWindow(diff_cmd), desc = "diff/window" },
          { key = "h", action = wezmacs.action.SmartSplit("gh dash"), desc = "github/split" },
          { key = "H", action = wezmacs.action.NewTab("gh dash"), desc = "github/split" },
        },
      },
    }
  end,
}
