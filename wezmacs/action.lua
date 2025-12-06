--[[
  WezMacs Action API

  Provides action functions ready for use in keybindings.
  Import as: local act = require("wezmacs.action")
]]

local wezterm = require("wezterm")
local wezterm_act = wezterm.action

local M = {}

-- Export wezterm.action as term for convenience
M.term = wezterm_act

-- Helper: wrap command string in shell
-- Commands should always run in shell to get correct environment (PATH, etc.)
local function wrap_in_shell(command)
  local wezmacs = require("wezmacs")
  return { wezmacs.config.shell, "-lc", command }
end

-- Smart split action - auto-orients based on window aspect ratio
-- Tall windows split horizontally (Bottom), wide windows split vertically (Right)
---@param command string Shell command string
---@return function Action callback
function M.SmartSplit(command)
  return function(window, pane)
    local args = wrap_in_shell(command)
    local dims = pane:get_dimensions()
    local direction = dims.pixel_height > dims.pixel_width and "Bottom" or "Right"
    pane:split({
      direction = direction,
      size = 0.5,
      args = args,
    })
  end
end

-- New tab action
---@param command string Shell command string
---@return table WezTerm action
function M.NewTab(command)
  local args = wrap_in_shell(command)
  return wezterm_act.SpawnCommandInNewTab({ args = args })
end

-- New window action
---@param command string Shell command string
---@return table WezTerm action
function M.NewWindow(command)
  local args = wrap_in_shell(command)
  return wezterm_act.SpawnCommandInNewWindow({ args = args })
end

-- Re-export common WezTerm actions for convenience
M.ReloadConfiguration = wezterm_act.ReloadConfiguration
M.ShowDebugOverlay = wezterm_act.ShowDebugOverlay
M.ActivateCommandPalette = wezterm_act.ActivateCommandPalette
M.CharSelect = wezterm_act.CharSelect
M.QuickSelect = wezterm_act.QuickSelect
M.ActivateCopyMode = wezterm_act.ActivateCopyMode
M.CopyTo = wezterm_act.CopyTo
M.PasteFrom = wezterm_act.PasteFrom
M.SpawnWindow = wezterm_act.SpawnWindow
M.Hide = wezterm_act.Hide
M.HideApplication = wezterm_act.HideApplication
M.ToggleFullScreen = wezterm_act.ToggleFullScreen
M.IncreaseFontSize = wezterm_act.IncreaseFontSize
M.DecreaseFontSize = wezterm_act.DecreaseFontSize
M.ResetFontSize = wezterm_act.ResetFontSize
M.SpawnTab = wezterm_act.SpawnTab
M.CloseCurrentTab = wezterm_act.CloseCurrentTab
M.ActivateTabRelative = wezterm_act.ActivateTabRelative
M.MoveTabRelative = wezterm_act.MoveTabRelative
M.ActivateTab = wezterm_act.ActivateTab
M.SplitVertical = wezterm_act.SplitVertical
M.SplitHorizontal = wezterm_act.SplitHorizontal
M.TogglePaneZoomState = wezterm_act.TogglePaneZoomState
M.CloseCurrentPane = wezterm_act.CloseCurrentPane
M.ActivatePaneDirection = wezterm_act.ActivatePaneDirection
M.AdjustPaneSize = wezterm_act.AdjustPaneSize
M.ScrollToPrompt = wezterm_act.ScrollToPrompt
M.ClearScrollback = wezterm_act.ClearScrollback
M.Search = wezterm_act.Search
M.QuickSelectArgs = wezterm_act.QuickSelectArgs

return M
