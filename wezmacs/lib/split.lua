--[[
  WezMacs Split Utility

  Provides smart split functionality that automatically determines
  split direction based on pane dimensions.
]]

local M = {}

-- Create a smart split that auto-orients based on window aspect ratio
-- Tall windows split horizontally (Bottom), wide windows split vertically (Right)
---@param pane table WezTerm pane object
---@param args table Command arguments to run in the new split
function M.smart_split(pane, args)
  local dims = pane:get_dimensions()
  local direction = dims.pixel_height > dims.pixel_width and "Bottom" or "Right"
  pane:split({
    direction = direction,
    size = 0.5,
    args = args,
  })
end

return M
