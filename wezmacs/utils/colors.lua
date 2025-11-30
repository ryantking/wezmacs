--[[
  WezMacs Color Utilities

  Helper functions for color manipulation and manipulation.
  Supports common color operations for theme customization.
]]

local M = {}

-- Parse hex color string to RGB components
---@param hex string Hex color string (e.g., "#FF0000" or "FF0000")
---@return number, number, number Red, Green, Blue values (0-255)
function M.parse_hex(hex)
  hex = hex:gsub("^#", "")

  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)

  return r or 0, g or 0, b or 0
end

-- Convert RGB components to hex string
---@param r number Red (0-255)
---@param g number Green (0-255)
---@param b number Blue (0-255)
---@return string Hex color string (e.g., "#FF0000")
function M.to_hex(r, g, b)
  return string.format("#%02X%02X%02X", math.floor(r), math.floor(g), math.floor(b))
end

-- Blend two colors with given alpha
---@param color1 string First color (hex)
---@param color2 string Second color (hex)
---@param alpha number Blend factor (0-1, where 0=color1, 1=color2)
---@return string Blended color (hex)
function M.blend(color1, color2, alpha)
  alpha = math.max(0, math.min(1, alpha))

  local r1, g1, b1 = M.parse_hex(color1)
  local r2, g2, b2 = M.parse_hex(color2)

  local r = r1 * (1 - alpha) + r2 * alpha
  local g = g1 * (1 - alpha) + g2 * alpha
  local b = b1 * (1 - alpha) + b2 * alpha

  return M.to_hex(r, g, b)
end

-- Darken a color by reducing brightness
---@param color string Color (hex)
---@param amount number Amount to darken (0-1, where 0.1 = 10% darker)
---@return string Darkened color (hex)
function M.darken(color, amount)
  amount = math.max(0, math.min(1, amount))
  return M.blend(color, "#000000", amount)
end

-- Lighten a color by increasing brightness
---@param color string Color (hex)
---@param amount number Amount to lighten (0-1, where 0.1 = 10% lighter)
---@return string Lightened color (hex)
function M.lighten(color, amount)
  amount = math.max(0, math.min(1, amount))
  return M.blend(color, "#FFFFFF", amount)
end

-- Convert RGB to HSL for advanced color operations
---@param r number Red (0-255)
---@param g number Green (0-255)
---@param b number Blue (0-255)
---@return number, number, number Hue (0-360), Saturation (0-1), Lightness (0-1)
function M.rgb_to_hsl(r, g, b)
  r = r / 255
  g = g / 255
  b = b / 255

  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local l = (max + min) / 2

  if max == min then
    return 0, 0, l
  end

  local d = max - min
  local s = l > 0.5 and d / (2 - max - min) or d / (max + min)

  local h
  if max == r then
    h = (g - b) / d + (g < b and 6 or 0)
  elseif max == g then
    h = (b - r) / d + 2
  else
    h = (r - g) / d + 4
  end
  h = h / 6

  return h * 360, s, l
end

-- Convert HSL to RGB
---@param h number Hue (0-360)
---@param s number Saturation (0-1)
---@param l number Lightness (0-1)
---@return number, number, number Red (0-255), Green (0-255), Blue (0-255)
function M.hsl_to_rgb(h, s, l)
  h = h / 360

  local function hue_to_rgb(p, q, t)
    if t < 0 then
      t = t + 1
    end
    if t > 1 then
      t = t - 1
    end
    if t < 1 / 6 then
      return p + (q - p) * 6 * t
    end
    if t < 1 / 2 then
      return q
    end
    if t < 2 / 3 then
      return p + (q - p) * (2 / 3 - t) * 6
    end
    return p
  end

  local r, g, b
  if s == 0 then
    r, g, b = l, l, l
  else
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue_to_rgb(p, q, h + 1 / 3)
    g = hue_to_rgb(p, q, h)
    b = hue_to_rgb(p, q, h - 1 / 3)
  end

  return r * 255, g * 255, b * 255
end

-- Rotate hue of a color
---@param color string Color (hex)
---@param degrees number Degrees to rotate hue (0-360)
---@return string Color with rotated hue (hex)
function M.rotate_hue(color, degrees)
  local r, g, b = M.parse_hex(color)
  local h, s, l = M.rgb_to_hsl(r, g, b)

  h = (h + degrees) % 360
  r, g, b = M.hsl_to_rgb(h, s, l)

  return M.to_hex(r, g, b)
end

-- Adjust saturation of a color
---@param color string Color (hex)
---@param factor number Saturation factor (0.5 = less saturated, 2.0 = more saturated)
---@return string Color with adjusted saturation (hex)
function M.saturate(color, factor)
  local r, g, b = M.parse_hex(color)
  local h, s, l = M.rgb_to_hsl(r, g, b)

  s = math.max(0, math.min(1, s * factor))
  r, g, b = M.hsl_to_rgb(h, s, l)

  return M.to_hex(r, g, b)
end

-- Invert a color
---@param color string Color (hex)
---@return string Inverted color (hex)
function M.invert(color)
  local r, g, b = M.parse_hex(color)
  return M.to_hex(255 - r, 255 - g, 255 - b)
end

-- Get a complementary color
---@param color string Color (hex)
---@return string Complementary color (hex)
function M.complement(color)
  return M.rotate_hue(color, 180)
end

return M
