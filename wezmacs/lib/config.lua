--[[
  WezMacs Config Utilities Library

  Provides utilities for configuration merging, validation, and manipulation.
  Used by module loader and modules for deep merging, path-based access, etc.
]]

local M = {}

-- Deep merge two tables, with override values taking precedence
-- Handles nested tables recursively
---@param base table Base configuration table
---@param override table Override configuration table
---@return table Merged configuration
function M.deep_merge(base, override)
  if type(override) ~= "table" then
    return override
  end

  if type(base) ~= "table" then
    return override
  end

  local result = {}

  -- Copy base values
  for k, v in pairs(base) do
    result[k] = v
  end

  -- Merge override values
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = M.deep_merge(result[k], v)
    else
      result[k] = v
    end
  end

  return result
end

-- Extend a nested path in a table with a value
-- Creates intermediate tables if they don't exist
---@param tbl table Table to extend
---@param path string Dot-separated path (e.g., "features.lazygit.enabled")
---@param value any Value to set at path
function M.extend(tbl, path, value)
  local keys = {}
  for key in string.gmatch(path, "[^.]+") do
    table.insert(keys, key)
  end

  local current = tbl
  for i = 1, #keys - 1 do
    local key = keys[i]
    if type(current[key]) ~= "table" then
      current[key] = {}
    end
    current = current[key]
  end

  local final_key = keys[#keys]
  if type(current[final_key]) == "table" and type(value) == "table" then
    current[final_key] = M.deep_merge(current[final_key], value)
  else
    current[final_key] = value
  end
end

-- Get a nested value from a table using dot notation
---@param tbl table Table to read from
---@param path string Dot-separated path (e.g., "features.lazygit.enabled")
---@param default any Default value if path doesn't exist
---@return any Value at path or default
function M.get(tbl, path, default)
  local keys = {}
  for key in string.gmatch(path, "[^.]+") do
    table.insert(keys, key)
  end

  local current = tbl
  for _, key in ipairs(keys) do
    if type(current) ~= "table" then
      return default
    end
    current = current[key]
    if current == nil then
      return default
    end
  end

  return current
end

-- Create a shallow copy of a table
---@param tbl table Table to copy
---@return table Shallow copy
function M.shallow_copy(tbl)
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = v
  end
  return copy
end

-- Check if a module is enabled based on spec and opts
---@param spec table Module spec (may have enabled field)
---@param opts table Module options (may have enabled field)
---@return boolean True if module should be enabled
function M.is_enabled(spec, opts)
  -- Check opts.enabled first (user override)
  if opts and opts.enabled == false then
    return false
  end

  -- Check spec.enabled (can be boolean or function)
  if spec.enabled == false then
    return false
  end

  if type(spec.enabled) == "function" then
    local registry = require("wezmacs.lib.registry")
    local ctx = {
      has_command = registry.has_command,
      has_module = registry.is_loaded,
    }
    return spec.enabled(ctx)
  end

  return true
end

return M
