--[[
  WezMacs Module Registry

  Central registry for module discovery, validation, and dependency resolution.
  Handles module specs, load order, and dependency checking.
]]

local M = {}

-- Registry of all loaded module specs
local _specs = {}
local _loaded_modules = {}

-- Register a module spec
---@param spec table Module spec table
function M.register(spec)
  if not spec.name then
    error("Module spec must have a 'name' field")
  end
  _specs[spec.name] = spec
end

-- Get all registered specs
---@return table Map of module name -> spec
function M.get_all_specs()
  return _specs
end

-- Get spec by name
---@param name string Module name
---@return table|nil Module spec or nil if not found
function M.get_spec(name)
  return _specs[name]
end

-- Check if module is loaded
---@param name string Module name
---@return boolean True if module is loaded
function M.is_loaded(name)
  return _loaded_modules[name] == true
end

-- Mark module as loaded
---@param name string Module name
function M.mark_loaded(name)
  _loaded_modules[name] = true
end

-- Resolve load order based on dependencies and priorities
-- Uses topological sort to respect dependencies, then sorts by priority
---@param module_names table Array of module names to load
---@return table Array of module names in load order
function M.resolve_load_order(module_names)
  local order = {}
  local visited = {}
  local visiting = {}

  -- Depth-first topological sort
  local function visit(name)
    if visited[name] then
      return
    end
    if visiting[name] then
      error("Circular dependency detected: " .. name)
    end

    visiting[name] = true

    local spec = _specs[name]
    -- Support both old format (dependencies.modules) and new format (deps for external only)
    -- Module dependencies would be in a separate field if needed
    if spec and spec.dependencies and spec.dependencies.modules then
      for _, dep in ipairs(spec.dependencies.modules) do
        visit(dep)
      end
    end

    visiting[name] = nil
    visited[name] = true
    table.insert(order, name)
  end

  -- Visit all requested modules
  for _, name in ipairs(module_names) do
    visit(name)
  end

  -- Sort by priority (higher priority = earlier in list)
  table.sort(order, function(a, b)
    local spec_a = _specs[a]
    local spec_b = _specs[b]

    local priority_a = spec_a and spec_a.priority or 50
    local priority_b = spec_b and spec_b.priority or 50

    return priority_a > priority_b
  end)

  return order
end

-- Check if external command is available
---@param cmd string Command name to check
---@return boolean True if command exists in PATH
function M.has_command(cmd)
  local handle = io.popen("command -v " .. cmd .. " 2>/dev/null")
  if not handle then
    return false
  end

  local result = handle:read("*a")
  handle:close()

  return result ~= "" and result ~= nil
end

-- Validate module dependencies
---@param spec table Module spec
---@return boolean, table True if all dependencies met, array of missing dependencies
function M.validate_dependencies(spec)
  local missing = {}

  -- Check deps (external binaries) - new format
  if spec.deps and type(spec.deps) == "table" then
    for _, cmd in ipairs(spec.deps) do
      if not M.has_command(cmd) then
        table.insert(missing, "external:" .. cmd)
      end
    end
  end

  -- Check dependencies.external - old format (backward compat)
  if spec.dependencies and spec.dependencies.external then
    for _, cmd in ipairs(spec.dependencies.external) do
      if not M.has_command(cmd) then
        table.insert(missing, "external:" .. cmd)
      end
    end
  end

  -- Check module dependencies - old format (backward compat)
  if spec.dependencies and spec.dependencies.modules then
    for _, dep_name in ipairs(spec.dependencies.modules) do
      if not _specs[dep_name] then
        table.insert(missing, "module:" .. dep_name)
      end
    end
  end

  return #missing == 0, missing
end

return M
