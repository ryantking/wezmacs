--[[
  Module: app
  Description: Application launchers and integrations (editors, file managers, docker, kubernetes, media, system monitor)
]]

local act = require("wezmacs.action")
local wezterm = require("wezterm")

return {
  name = "app",
  description = "Application launchers and integrations",

  deps = { "lazydocker", "yazi", "k9s", "spotify_player", "btm" },

  opts = function()
    return {
      -- Editor options
      editor = "vim",
      ide = "code",
      
      -- File manager options
      file_manager = "yazi",
      
      -- Keybindings (all use LEADER modifier by default)
      docker_key = "d",
      file_manager_key = "f",
      editor_key = "e",
      kubernetes_key = "k",
      media_key = "m",
      system_monitor_key = "h",
    }
  end,

  keys = function(opts)
    local editor = opts.editor or "vim"
    local ide = opts.ide or "code"
    local file_manager = opts.file_manager or "yazi"
    
    return {
      LEADER = {
        -- Editor bindings
        Enter = {
          action = act.NewTab(editor),
          desc = "app/editor-open",
        },
        [opts.editor_key or "e"] = {
          e = { action = act.SmartSplit(editor), desc = "app/editor-split" },
          E = { action = act.NewTab(editor), desc = "app/editor-tab" },
          v = {
            action = function(window, pane)
              local cwd_uri = pane:get_current_working_dir()
              local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
              wezterm.background_child_process({ ide, cwd })
            end,
            desc = "app/launch-ide",
          },
        },
        
        -- File manager bindings
        [opts.file_manager_key or "f"] = {
          f = { action = act.SmartSplit(file_manager), desc = "app/file-manager-split" },
          F = { action = act.NewTab(file_manager), desc = "app/file-manager-tab" },
          s = {
            action = act.SmartSplit("sudo " .. file_manager .. " /"),
            desc = "app/file-manager-sudo-split",
          },
          S = {
            action = act.NewTab("sudo " .. file_manager .. " /"),
            desc = "app/file-manager-sudo-tab",
          },
        },
        
        -- Docker bindings
        [opts.docker_key or "d"] = {
          d = { action = act.SmartSplit("lazydocker"), desc = "app/docker-split" },
          D = { action = act.NewTab("lazydocker"), desc = "app/docker-tab" },
        },
        
        -- Kubernetes bindings
        [opts.kubernetes_key or "k"] = {
          action = act.NewTab("k9s"),
          desc = "app/kubernetes",
        },
        
        -- Media bindings
        [opts.media_key or "m"] = {
          action = act.NewTab("spotify_player"),
          desc = "app/media",
        },
        
        -- System monitor bindings
        [opts.system_monitor_key or "h"] = {
          action = act.NewTab("btm"),
          desc = "app/system-monitor",
        },
      },
    }
  end,

  setup = function(config, opts)
    -- Module-specific setup (if any)
  end,
}
