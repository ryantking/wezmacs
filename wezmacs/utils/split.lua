local M = {}

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
