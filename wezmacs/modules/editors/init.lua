--[[
  Module: editors
  Category: development
  Description: External code editor launchers (terminal editor and IDE)
]]

local act = require("wezmacs.action")
local wezterm = require("wezterm")

return {
  name = "editors",
  category = "development",
  description = "External code editor launchers",

  deps = {},

  opts = function()
    return {
      editor = "vim",
      ide = "code",
      editor_split_key = "e",
      editor_tab_key = "E",
      ide_key = "i",
    }
  end,

  keys = function(opts)
    local editor = opts.editor or "vim"
    local ide = opts.ide or "code"
    
    return {
      LEADER = {
        e = {
          action = act.SmartSplit(editor),
          desc = "editors/editor-split",
        },
        E = {
          action = act.NewTab(editor),
          desc = "editors/editor-tab",
        },
        i = {
          action = function(window, pane)
            local cwd_uri = pane:get_current_working_dir()
            local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
            wezterm.background_child_process({ ide, cwd })
          end,
          desc = "editors/launch-ide",
        },
      },
    }
  end,

  enabled = true,

  priority = 50,

  setup = function(config, opts)
    -- Module-specific setup (if any)
  end,
}
