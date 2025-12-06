--[[
  WezMacs Theme Library

  Provides standardized access to theme colors across modules.
  Caches theme lookups for performance.
]]

local wezterm = require("wezterm")

local M = {}

-- Cached theme to avoid repeated lookups
local _cached_theme = nil
local _cached_scheme_name = nil

-- Get current theme colors
---@return table|nil Theme color scheme or nil if not available
function M.get_colors()
  -- Access global wezmacs API (may not be initialized yet)
  if not _G.wezmacs then
    return nil
  end

  local theme_mod = _G.wezmacs.get_module("theme")

  if not theme_mod or not theme_mod.color_scheme then
    return nil
  end

  -- Use cache if scheme hasn't changed
  if _cached_theme and _cached_scheme_name == theme_mod.color_scheme then
    return _cached_theme
  end

  -- Load theme
  local scheme = wezterm.get_builtin_color_schemes()[theme_mod.color_scheme]
  if not scheme then
    return nil
  end

  _cached_theme = scheme
  _cached_scheme_name = theme_mod.color_scheme

  return scheme
end

-- Get specific color from theme with fallback
-- Supports dot notation: "ansi.3" or "brights.2"
---@param color_name string Dot-separated color path
---@param fallback string|nil Fallback color if not found
---@return string Color value or fallback
function M.get_color(color_name, fallback)
  local theme = M.get_colors()

  if not theme then
    return fallback
  end

  -- Support dot notation: "ansi.3" or "brights.2"
  local parts = {}
  for part in string.gmatch(color_name, "[^.]+") do
    table.insert(parts, part)
  end

  local value = theme
  for _, part in ipairs(parts) do
    if type(value) ~= "table" then
      return fallback
    end

    -- Handle numeric indices
    local index = tonumber(part)
    if index then
      value = value[index]
    else
      value = value[part]
    end

    if value == nil then
      return fallback
    end
  end

  return value or fallback
end

-- Semantic color accessors (common use cases)
---@param fallback string|nil Fallback color
---@return string Accent color (typically cyan/green)
function M.get_accent_color(fallback)
  return M.get_color("ansi.3", fallback or "#00ff00")
end

---@param fallback string|nil Fallback color
---@return string Error color (typically red)
function M.get_error_color(fallback)
  return M.get_color("ansi.2", fallback or "#ff0000")
end

---@param fallback string|nil Fallback color
---@return string Warning color (typically yellow)
function M.get_warning_color(fallback)
  return M.get_color("ansi.4", fallback or "#ffff00")
end

---@return string Background color
function M.get_background()
  return M.get_color("background", "#000000")
end

---@return string Foreground color
function M.get_foreground()
  return M.get_color("foreground", "#ffffff")
end

-- Register a color consumer (for modules that need theme updates)
-- This enables future "live reload" theme support
local _consumers = {}

---@param module_name string Module name
---@param callback function Callback function to call when theme changes
function M.register_consumer(module_name, callback)
  _consumers[module_name] = callback
end

-- Notify all consumers that theme has changed
function M.notify_theme_changed()
  _cached_theme = nil
  _cached_scheme_name = nil

  for module_name, callback in pairs(_consumers) do
    callback()
  end
end

return M
