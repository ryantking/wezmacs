--[[
  WezMacs Framework Bootstrap

  Main entry point for the WezMacs modular wezterm configuration framework.
  Orchestrates module loading, configuration merging, and initialization.
]]

local wezterm = require("wezterm")
local module_loader = require("wezmacs.module")

local M = {}

-- Main setup function called from wezterm.lua
---@param config table WezTerm config object from config_builder()
---@param opts table Optional configuration options
function M.setup(config, opts)
  opts = opts or {}

  -- Setup logging function
  local log_level = opts.log_level or "info"
  local function log(level, msg)
    local prefix = "[WezMacs] "
    if level == "error" then
      wezterm.log_error(prefix .. msg)
    elseif level == "warn" then
      wezterm.log_info(prefix .. "WARN: " .. msg)
    elseif level ~= "debug" or log_level == "debug" then
      wezterm.log_info(prefix .. msg)
    end
  end

  -- Use unified config (single table where keys are module names)
  local unified_config = opts.unified_config or {}

  log("info", "Loading WezMacs framework with unified config")

  -- Load all modules with config merging
  local modules, states = module_loader.load_all(
    unified_config,
    log
  )

  -- Create global wezmacs API table (captured closure over states)
  _G.wezmacs = {
    -- Get full merged config for a module (includes features)
    -- Returns a shallow copy to prevent closures from sharing mutable references
    get_module = function(module_name)
      local state = states[module_name]
      if not state then
        log("warn", "No config found for module: " .. module_name)
        return { features = {} }
      end

      -- Return shallow copy to avoid shared mutable state in closures
      local copy = {}
      for k, v in pairs(state) do
        copy[k] = v
      end
      return copy
    end,

    -- Get module spec (new format)
    get_spec = function(module_name)
      local registry = require("wezmacs.lib.registry")
      return registry.get_spec(module_name)
    end,

    -- Check if module is loaded
    has_module = function(module_name)
      local registry = require("wezmacs.lib.registry")
      return registry.is_loaded(module_name)
    end,

    -- Library access
    lib = {
      keybindings = require("wezmacs.lib.keybindings"),
      theme = require("wezmacs.lib.theme"),
      config = require("wezmacs.lib.config"),
    },
    -- Action API (top-level, not in lib)
    action = require("wezmacs.action"),
  }

  local keybindings = require("wezmacs.lib.keybindings")

  -- Apply CORE module first if present (core settings must be applied before others)
  for i, spec in ipairs(modules) do
    if spec.name == "core" then
      log("info", "Applying CORE module first")
      if spec.setup then
        local opts = states[spec.name]
        spec.setup(config, opts)
      end
      table.remove(modules, i)
      break
    end
  end

  -- Apply remaining modules
  for _, spec in ipairs(modules) do
    local mod_name = spec.name or "unknown"
    log("info", "Applying module: " .. mod_name)

    -- Call setup with config and opts
    if spec.setup then
      local opts = states[mod_name]
      spec.setup(config, opts)
    end

    -- Apply keybindings if module has keys defined
    if spec.keys then
      local opts = states[mod_name]
      keybindings.apply_keys(config, spec, opts)
    end
  end

  log("info", "WezMacs framework initialized successfully (" .. #modules .. " modules loaded)")
end

return M
