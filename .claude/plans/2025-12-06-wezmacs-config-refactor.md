# WezMacs Configuration Refactor Plan

## Executive Summary

This plan outlines a comprehensive refactor of WezMacs' configuration system inspired by LazyVim's ergonomic design patterns. The goal is to reduce boilerplate, improve module ergonomics, enable better cross-module communication, and provide standardized libraries for common patterns like keybindings and theme integration.

---

## 1. GOALS & DESIGN PRINCIPLES

### Primary Goals
1. **Reduce Boilerplate**: Eliminate repetitive patterns in module definitions (especially keybindings)
2. **Improve Ergonomics**: Make module configuration more intuitive and declarative
3. **Enable Module Communication**: Provide standardized ways for modules to share state (especially theme colors)
4. **Simplify User Configuration**: More intuitive config format with better discoverability
5. **Maintain Backward Compatibility**: Provide migration path for existing configs

### Design Principles (from LazyVim)
- **Convention over Configuration**: Sensible defaults, minimal required config
- **Declarative Specs**: Module behavior defined via data structures, not imperative code
- **Lazy Loading Ready**: Support conditional/lazy module loading patterns
- **Deep Merging**: User config merges with defaults at all levels
- **Utilities as Library**: Provide `wezmacs.lib.*` utilities for common patterns

---

## 2. NEW CONFIGURATION FORMAT

### 2.1 Module Spec Format

**Inspired by LazyVim's plugin spec, adapted for WezMacs modules:**

```lua
-- NEW: wezmacs/modules/git/spec.lua
return {
  name = "git",
  category = "integration",
  description = "Lazygit integration with smart splitting",

  -- External dependencies
  dependencies = {
    external = { "lazygit", "delta" },  -- External tools
    modules = { "theme", "keybindings" },  -- Other WezMacs modules
  },

  -- Default configuration
  opts = {
    leader_key = "g",
    leader_mod = "LEADER",

    features = {
      lazygit = { enabled = true, split_mode = "half" },
      git_diff = { enabled = true },
      git_log = { enabled = true },
    },
  },

  -- Declarative keybinding spec
  keys = {
    -- Leader-based submenu (auto-creates key table)
    {
      leader = "g",  -- Triggers on LEADER+g
      submenu = "git",  -- Creates git key table
      bindings = {
        { key = "g", desc = "Open lazygit", action = "actions.lazygit_smart_split" },
        { key = "G", desc = "Lazygit in new tab", action = "actions.lazygit_new_tab" },
        { key = "d", desc = "Git diff", action = "actions.git_diff_smart_split" },
        { key = "l", desc = "Git log", action = "actions.git_log_smart_split" },
      },
    },
    -- Direct keybindings (no submenu)
    {
      key = "r",
      mods = "SUPER|SHIFT",
      desc = "Quick git status",
      action = "actions.git_status_overlay",
    },
  },

  -- Conditional loading (future enhancement)
  enabled = function(ctx)
    return ctx.has_command("lazygit")
  end,

  -- Priority for load order (higher = earlier)
  priority = 50,  -- Default is 50, theme uses 100, core uses 1000
}
```

**Key Improvements:**
- **Declarative keybindings**: No more manual key table setup
- **Dependency declaration**: Explicit module and tool dependencies
- **Feature flags**: Standardized nested opts structure
- **Conditional loading**: Can disable if dependencies missing
- **Priority-based ordering**: Replaces hardcoded load order array

---

### 2.2 User Configuration Format

**NEW: ~/.config/wezmacs/init.lua**

```lua
-- LazyVim-style: modules directory auto-loaded
-- Each file in ~/.config/wezmacs/modules/*.lua is a module override

return {
  -- Global settings
  settings = {
    leader = { key = "Space", mods = "SUPER" },
    modifier = "SUPER",  -- Default modifier for keybindings
  },

  -- Module configuration (auto-merged with module specs)
  modules = {
    -- Simple override
    theme = {
      color_scheme = "Horizon Dark (Gogh)",
    },

    -- Nested feature flags
    fonts = {
      font = "Iosevka Mono",
      font_size = 18,
      features = {
        ligatures = { enabled = true },
      },
    },

    -- Override keybindings
    git = {
      leader_key = "g",
      keys = {
        -- Add new keybinding to git submenu
        { key = "s", desc = "Git stash", action = function(window, pane)
          -- Custom action
        end },
        -- Disable built-in keybinding
        { key = "G", enabled = false },
      },
    },

    -- Disable entire module
    docker = { enabled = false },
  },

  -- Custom modules (loaded from user.custom-modules.*)
  custom = {
    "my-custom-workflow",
    "my-ssh-manager",
  },
}
```

**Alternative: Auto-loading pattern (like LazyVim's plugins/)**

```
~/.config/wezmacs/
├── init.lua              # Minimal config (global settings only)
└── modules/
    ├── theme.lua         # Override theme module
    ├── git.lua           # Override git module
    └── my-custom.lua     # Custom module
```

Each file in `modules/` returns a module spec that gets auto-merged.

---

### 2.3 Migration Path

Provide compatibility layer to support old format:

```lua
-- wezmacs/compat.lua
local M = {}

-- Detect if config is old format (flat table with module names as keys)
function M.is_legacy_format(config)
  -- Old format: { core = {...}, theme = {...} }
  -- New format: { settings = {...}, modules = {...} }
  return config.modules == nil and config.settings == nil
end

-- Convert old format to new format
function M.migrate_config(old_config)
  return {
    modules = old_config,  -- Old format becomes modules table
  }
end

return M
```

---

## 3. WEZMACS LIBRARY SYSTEM

### 3.1 Keybinding Library (`wezmacs/lib/keybindings.lua`)

**Purpose**: Eliminate keybinding boilerplate, provide declarative API

```lua
-- NEW FILE: wezmacs/lib/keybindings.lua
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Create a submenu (key table) from declarative spec
function M.create_submenu(config, spec)
  local name = spec.submenu
  local leader_key = spec.leader
  local leader_mods = spec.leader_mods or "LEADER"

  -- Initialize key_tables if needed
  config.key_tables = config.key_tables or {}

  -- Build key table from bindings
  config.key_tables[name] = {}
  for _, binding in ipairs(spec.bindings) do
    if binding.enabled ~= false then  -- Allow disabling individual keys
      table.insert(config.key_tables[name], {
        key = binding.key,
        action = M.resolve_action(binding.action),
      })
    end
  end

  -- Always add Escape to exit submenu
  table.insert(config.key_tables[name], {
    key = "Escape",
    action = "PopKeyTable",
  })

  -- Add leader key to activate submenu
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = leader_key,
    mods = leader_mods,
    action = act.ActivateKeyTable({
      name = name,
      one_shot = false,
      until_unknown = true,
    }),
  })
end

-- Resolve action from string path or function
function M.resolve_action(action)
  if type(action) == "function" then
    return wezterm.action_callback(action)
  elseif type(action) == "string" then
    -- Format: "actions.function_name" or "module.actions.function_name"
    local parts = {}
    for part in string.gmatch(action, "[^.]+") do
      table.insert(parts, part)
    end

    if #parts == 2 then
      -- "actions.function_name" - assume current module
      -- This gets resolved later with module context
      return action
    elseif #parts == 3 then
      -- "module.actions.function_name" - explicit module
      local mod = require("wezmacs.modules." .. parts[1] .. "." .. parts[2])
      return wezterm.action_callback(mod[parts[3]])
    end
  end

  return action  -- Pass through WezTerm action
end

-- Add direct keybinding (not in submenu)
function M.add_key(config, spec)
  config.keys = config.keys or {}

  if spec.enabled ~= false then
    table.insert(config.keys, {
      key = spec.key,
      mods = spec.mods,
      action = M.resolve_action(spec.action),
    })
  end
end

-- Process all keybindings from module spec
function M.apply_keys(config, module_spec, module_actions)
  if not module_spec.keys then return end

  for _, key_spec in ipairs(module_spec.keys) do
    if key_spec.submenu then
      -- Resolve action strings to actual functions
      for _, binding in ipairs(key_spec.bindings) do
        if type(binding.action) == "string" and binding.action:match("^actions%.") then
          local func_name = binding.action:match("^actions%.(.+)$")
          binding.action = module_actions[func_name]
        end
      end

      M.create_submenu(config, key_spec)
    else
      -- Direct keybinding
      if type(key_spec.action) == "string" and key_spec.action:match("^actions%.") then
        local func_name = key_spec.action:match("^actions%.(.+)$")
        key_spec.action = module_actions[func_name]
      end

      M.add_key(config, key_spec)
    end
  end
end

return M
```

**Usage in modules:**

```lua
-- NEW: wezmacs/modules/git/init.lua (simplified)
local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.git.actions")
local spec = require("wezmacs.modules.git.spec")

local M = {}

function M.apply_to_config(config, opts)
  -- Apply keybindings using library
  keybindings.apply_keys(config, spec, actions)

  -- Other module-specific config
  -- ...
end

return M
```

**Before/After Comparison:**

```lua
-- BEFORE: ~50 lines of boilerplate per module
config.key_tables = config.key_tables or {}
config.key_tables.git = {
  { key = "g", action = wezterm.action_callback(actions.lazygit_smart_split) },
  { key = "G", action = act.SpawnCommandInNewTab({ args = { "lazygit" } }) },
  { key = "Escape", action = "PopKeyTable" },
}

config.keys = config.keys or {}
table.insert(config.keys, {
  key = mod.leader_key,
  mods = mod.leader_mod,
  action = act.ActivateKeyTable({
    name = "git",
    one_shot = false,
    until_unknown = true,
  }),
})

-- AFTER: ~5 lines, declarative
keybindings.apply_keys(config, spec, actions)
```

---

### 3.2 Theme Library (`wezmacs/lib/theme.lua`)

**Purpose**: Standardize theme color access across modules

```lua
-- NEW FILE: wezmacs/lib/theme.lua
local wezterm = require("wezterm")

local M = {}

-- Cached theme to avoid repeated lookups
local _cached_theme = nil
local _cached_scheme_name = nil

-- Get current theme colors
function M.get_colors()
  local theme_mod = wezmacs.get_module("theme")

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
function M.get_accent_color(fallback)
  return M.get_color("ansi.3", fallback or "#00ff00")  -- Typically cyan/green
end

function M.get_error_color(fallback)
  return M.get_color("ansi.2", fallback or "#ff0000")  -- Typically red
end

function M.get_warning_color(fallback)
  return M.get_color("ansi.4", fallback or "#ffff00")  -- Typically yellow
end

function M.get_background()
  return M.get_color("background", "#000000")
end

function M.get_foreground()
  return M.get_color("foreground", "#ffffff")
end

-- Register a color consumer (for modules that need theme updates)
-- This enables future "live reload" theme support
local _consumers = {}

function M.register_consumer(module_name, callback)
  _consumers[module_name] = callback
end

function M.notify_theme_changed()
  _cached_theme = nil
  _cached_scheme_name = nil

  for module_name, callback in pairs(_consumers) do
    callback()
  end
end

return M
```

**Usage in modules:**

```lua
-- BEFORE: Ad-hoc theme access
local theme_mod = wezmacs.get_module("theme")
local prompt_color = "#56be8d"  -- Hardcoded fallback
if theme_mod and theme_mod.color_scheme then
  local theme = wezterm.get_builtin_color_schemes()[theme_mod.color_scheme]
  if theme and theme.ansi and theme.ansi[3] then
    prompt_color = theme.ansi[3]
  end
end

-- AFTER: Clean library access
local theme = require("wezmacs.lib.theme")
local prompt_color = theme.get_accent_color("#56be8d")
```

---

### 3.3 Action Helpers Library (`wezmacs/lib/actions.lua`)

**Purpose**: Reduce duplication in common action patterns

```lua
-- NEW FILE: wezmacs/lib/actions.lua
local split = require("wezmacs.utils.split")

local M = {}

-- Create a smart split action for a command
function M.smart_split_action(cmd_args, opts)
  opts = opts or {}

  return function(window, pane)
    local args = cmd_args

    -- Support function for dynamic args
    if type(cmd_args) == "function" then
      args = cmd_args(window, pane)
    end

    -- Add split mode if specified
    if opts.split_mode then
      table.insert(args, "-sm")
      table.insert(args, opts.split_mode)
    end

    split.smart_split(pane, args)
  end
end

-- Create a new tab action
function M.new_tab_action(cmd_args)
  local wezterm = require("wezterm")
  local act = wezterm.action

  return act.SpawnCommandInNewTab({ args = cmd_args })
end

-- Create an overlay action (for floating prompts/info)
function M.overlay_action(content_fn)
  local wezterm = require("wezterm")

  return function(window, pane)
    local content = content_fn(window, pane)

    -- Use WezTerm overlay/notification system
    window:toast_notification("WezMacs", content, nil, 5000)
  end
end

-- Create a shell command action
function M.shell_command_action(command, opts)
  opts = opts or {}

  return function(window, pane)
    local shell = os.getenv("SHELL") or "/bin/bash"
    local args = { shell, "-lc", command }

    if opts.new_tab then
      return M.new_tab_action(args)(window, pane)
    elseif opts.smart_split then
      return M.smart_split_action(args, { split_mode = opts.split_mode })(window, pane)
    else
      pane:send_text(command .. "\n")
    end
  end
end

return M
```

**Usage in modules:**

```lua
-- BEFORE: Repetitive action definitions
function M.lazygit_smart_split(window, pane)
  split.smart_split(pane, { "lazygit", "-sm", "half" })
end

function M.lazygit_new_tab(window, pane)
  return act.SpawnCommandInNewTab({ args = { "lazygit" } })
end

function M.git_diff_smart_split(window, pane)
  local shell = os.getenv("SHELL") or "/bin/bash"
  split.smart_split(pane, {
    shell,
    "-lc",
    "git diff main 2>/dev/null || git diff master 2>/dev/null",
  })
end

-- AFTER: Concise, declarative
local action_lib = require("wezmacs.lib.actions")

M.lazygit_smart_split = action_lib.smart_split_action(
  { "lazygit" },
  { split_mode = "half" }
)

M.lazygit_new_tab = action_lib.new_tab_action({ "lazygit" })

M.git_diff_smart_split = action_lib.shell_command_action(
  "git diff main 2>/dev/null || git diff master 2>/dev/null",
  { smart_split = true }
)
```

---

### 3.4 Module Registry (`wezmacs/lib/registry.lua`)

**Purpose**: Dynamic module discovery and dependency resolution

```lua
-- NEW FILE: wezmacs/lib/registry.lua
local M = {}

-- Registry of all loaded module specs
local _specs = {}
local _loaded_modules = {}

-- Register a module spec
function M.register(spec)
  _specs[spec.name] = spec
end

-- Get all registered specs
function M.get_all_specs()
  return _specs
end

-- Get spec by name
function M.get_spec(name)
  return _specs[name]
end

-- Check if module is loaded
function M.is_loaded(name)
  return _loaded_modules[name] == true
end

-- Mark module as loaded
function M.mark_loaded(name)
  _loaded_modules[name] = true
end

-- Resolve load order based on dependencies and priorities
function M.resolve_load_order(module_names)
  local order = {}
  local visited = {}
  local visiting = {}

  -- Depth-first topological sort
  local function visit(name)
    if visited[name] then return end
    if visiting[name] then
      error("Circular dependency detected: " .. name)
    end

    visiting[name] = true

    local spec = _specs[name]
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

-- Check if external dependency is available
function M.has_command(cmd)
  local handle = io.popen("command -v " .. cmd .. " 2>/dev/null")
  if not handle then return false end

  local result = handle:read("*a")
  handle:close()

  return result ~= ""
end

-- Validate module dependencies
function M.validate_dependencies(spec)
  if not spec.dependencies then return true, {} end

  local missing = {}

  -- Check external dependencies
  if spec.dependencies.external then
    for _, cmd in ipairs(spec.dependencies.external) do
      if not M.has_command(cmd) then
        table.insert(missing, "external:" .. cmd)
      end
    end
  end

  -- Check module dependencies
  if spec.dependencies.modules then
    for _, dep_name in ipairs(spec.dependencies.modules) do
      if not _specs[dep_name] then
        table.insert(missing, "module:" .. dep_name)
      end
    end
  end

  return #missing == 0, missing
end

return M
```

---

### 3.5 Config Utilities (`wezmacs/lib/config.lua`)

**Purpose**: Configuration merging, validation, and utilities

```lua
-- NEW FILE: wezmacs/lib/config.lua
local M = {}

-- Deep merge tables (improved from current implementation)
function M.deep_merge(base, override)
  if type(override) ~= "table" then
    return override
  end

  if type(base) ~= "table" then
    return override
  end

  local result = {}

  -- Copy base
  for k, v in pairs(base) do
    result[k] = v
  end

  -- Merge override
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = M.deep_merge(result[k], v)
    else
      result[k] = v
    end
  end

  return result
end

-- Extend a nested path in a table
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

-- Get a nested value from a table
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
function M.shallow_copy(tbl)
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = v
  end
  return copy
end

-- Check if a module is enabled
function M.is_enabled(spec, opts)
  -- Check opts.enabled first
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
```

---

## 4. NEW MODULE LOADER ARCHITECTURE

### 4.1 Enhanced Module Loader (`wezmacs/module.lua` - refactored)

```lua
-- REFACTORED: wezmacs/module.lua
local registry = require("wezmacs.lib.registry")
local config_lib = require("wezmacs.lib.config")

local M = {}

-- Discover all module specs
function M.discover_modules(log)
  local module_dirs = {
    "wezmacs.modules",  -- Built-in modules
    "user.custom-modules",  -- User custom modules
  }

  local specs = {}

  for _, base_path in ipairs(module_dirs) do
    -- Use Lua's package system to discover modules
    local pattern = base_path:gsub("%.", "/")
    local handle = io.popen("ls -1 " .. pattern .. " 2>/dev/null")

    if handle then
      for dir in handle:lines() do
        local spec_path = base_path .. "." .. dir .. ".spec"
        local ok, spec = pcall(require, spec_path)

        if ok and type(spec) == "table" then
          registry.register(spec)
          table.insert(specs, spec)
          log("info", "Discovered module: " .. spec.name)
        end
      end
      handle:close()
    end
  end

  return specs
end

-- Load and apply a single module
function M.load_module(spec, user_opts, log)
  -- Check if module is enabled
  if not config_lib.is_enabled(spec, user_opts) then
    log("info", "Module disabled: " .. spec.name)
    return nil
  end

  -- Validate dependencies
  local deps_ok, missing = registry.validate_dependencies(spec)
  if not deps_ok then
    log("warn", "Module " .. spec.name .. " missing dependencies: " .. table.concat(missing, ", "))
    return nil
  end

  -- Merge opts
  local opts = config_lib.deep_merge(spec.opts or {}, user_opts or {})

  -- Load module implementation
  local require_path = "wezmacs.modules." .. spec.name .. ".init"
  local ok, mod = pcall(require, require_path)

  if not ok then
    require_path = "user.custom-modules." .. spec.name .. ".init"
    ok, mod = pcall(require, require_path)
  end

  if not ok then
    log("error", "Failed to load module '" .. spec.name .. "': " .. tostring(mod))
    return nil
  end

  registry.mark_loaded(spec.name)

  return {
    spec = spec,
    opts = opts,
    impl = mod,
  }
end

-- Load all modules in dependency order
function M.load_all(user_config, log)
  log("info", "Discovering modules...")
  M.discover_modules(log)

  -- Get list of modules to load
  local module_names = {}
  if user_config.modules then
    for name, opts in pairs(user_config.modules) do
      if opts.enabled ~= false then
        table.insert(module_names, name)
      end
    end
  else
    -- Load all discovered modules
    for name, _ in pairs(registry.get_all_specs()) do
      table.insert(module_names, name)
    end
  end

  -- Add custom modules
  if user_config.custom then
    for _, name in ipairs(user_config.custom) do
      table.insert(module_names, name)
    end
  end

  -- Resolve load order
  local load_order = registry.resolve_load_order(module_names)

  log("info", "Load order: " .. table.concat(load_order, " -> "))

  -- Load modules
  local loaded = {}
  for _, name in ipairs(load_order) do
    local user_opts = user_config.modules and user_config.modules[name] or {}
    local module = M.load_module(registry.get_spec(name), user_opts, log)

    if module then
      loaded[name] = module
      log("info", "Loaded: " .. name)
    end
  end

  return loaded
end

return M
```

---

### 4.2 Enhanced Init (`wezmacs/init.lua` - refactored)

```lua
-- REFACTORED: wezmacs/init.lua
local module_loader = require("wezmacs.module")
local compat = require("wezmacs.compat")
local registry = require("wezmacs.lib.registry")

local M = {}

function M.setup(user_config)
  local wezterm = require("wezterm")

  -- Logging
  local function log(level, message)
    wezterm.log_info("[wezmacs:" .. level .. "] " .. message)
  end

  log("info", "Initializing WezMacs...")

  -- Handle legacy config format
  if compat.is_legacy_format(user_config) then
    log("warn", "Using legacy config format. Consider migrating to new format.")
    user_config = compat.migrate_config(user_config)
  end

  -- Load all modules
  local loaded_modules = module_loader.load_all(user_config, log)

  -- Create global API
  _G.wezmacs = {
    get_module = function(module_name)
      local module = loaded_modules[module_name]
      if not module then
        log("warn", "No module found: " .. module_name)
        return {}
      end

      -- Return shallow copy of opts
      local copy = {}
      for k, v in pairs(module.opts) do
        copy[k] = v
      end
      return copy
    end,

    get_spec = function(module_name)
      return registry.get_spec(module_name)
    end,

    has_module = function(module_name)
      return registry.is_loaded(module_name)
    end,

    lib = {
      keybindings = require("wezmacs.lib.keybindings"),
      theme = require("wezmacs.lib.theme"),
      actions = require("wezmacs.lib.actions"),
      config = require("wezmacs.lib.config"),
    },
  }

  -- Apply modules to config
  local config = wezterm.config_builder and wezterm.config_builder() or {}

  for _, module in pairs(loaded_modules) do
    if module.impl.apply_to_config then
      log("info", "Applying: " .. module.spec.name)
      module.impl.apply_to_config(config, module.opts)
    end
  end

  log("info", "WezMacs initialized successfully")

  return config
end

return M
```

---

## 5. IMPLEMENTATION ROADMAP

### Phase 1: Library Foundation (Week 1)
**Goal**: Build reusable libraries without breaking existing modules

**Tasks**:
1. Create `wezmacs/lib/` directory structure
2. Implement `wezmacs/lib/config.lua` (deep merge, extend, get)
3. Implement `wezmacs/lib/registry.lua` (module registry)
4. Implement `wezmacs/lib/keybindings.lua` (declarative keybinding API)
5. Implement `wezmacs/lib/theme.lua` (standardized theme access)
6. Implement `wezmacs/lib/actions.lua` (action helpers)
7. Add library exports to global `wezmacs.lib` API
8. Write unit tests for library functions

**Files to create**:
- `wezmacs/lib/config.lua`
- `wezmacs/lib/registry.lua`
- `wezmacs/lib/keybindings.lua`
- `wezmacs/lib/theme.lua`
- `wezmacs/lib/actions.lua`

**Success criteria**: Libraries work independently, no changes to existing modules yet

---

### Phase 2: Module Spec Format (Week 2)
**Goal**: Introduce new spec format alongside existing modules

**Tasks**:
1. Create `spec.lua` template for modules
2. Convert one simple module (theme) to new spec format
3. Convert one complex module (git) to new spec format
4. Update module loader to support both old and new formats
5. Test side-by-side compatibility
6. Document migration guide

**Files to modify**:
- `wezmacs/modules/theme/spec.lua` (new)
- `wezmacs/modules/theme/init.lua` (refactor to use spec)
- `wezmacs/modules/git/spec.lua` (new)
- `wezmacs/modules/git/init.lua` (refactor to use spec + libraries)
- `wezmacs/modules/git/actions.lua` (refactor using action helpers)

**Success criteria**: Git and theme modules work with new spec format, other modules unchanged

---

### Phase 3: Enhanced Module Loader (Week 3)
**Goal**: Refactor module loader to support specs, dependencies, priorities

**Tasks**:
1. Refactor `wezmacs/module.lua` to use registry
2. Implement dependency resolution
3. Implement priority-based load ordering
4. Implement conditional loading (enabled functions)
5. Add module discovery system
6. Test load order with complex dependencies

**Files to modify**:
- `wezmacs/module.lua` (major refactor)
- `wezmacs/init.lua` (integrate new loader)

**Success criteria**: All modules load correctly, dependencies resolved, priorities respected

---

### Phase 4: New User Config Format (Week 4)
**Goal**: Introduce new user config format with backward compatibility

**Tasks**:
1. Implement `wezmacs/compat.lua` (legacy format detection and migration)
2. Update `wezmacs/init.lua` to handle both formats
3. Create example config in new format
4. Update `wezmacs/generate-config.lua` to generate new format
5. Add auto-loading pattern for `~/.config/wezmacs/modules/*.lua`
6. Write migration documentation

**Files to create/modify**:
- `wezmacs/compat.lua` (new)
- `wezmacs/generate-config.lua` (update)
- `examples/init-new-format.lua` (new)
- `docs/migration-guide.md` (new)

**Success criteria**: Both old and new config formats work, migration path clear

---

### Phase 5: Module Conversion (Weeks 5-6)
**Goal**: Convert all remaining modules to new spec format

**Tasks**:
1. Convert workflow modules (docker, k8s, editors, etc.) - 6 modules
2. Convert integration modules (workspace, claude) - 2 modules
3. Convert UI modules (fonts, status-bar) - 2 modules
4. Convert core modules (core, keybindings) - 2 modules
5. Remove old module code patterns
6. Update all modules to use libraries

**Files to modify**: All 15 modules in `wezmacs/modules/`

**Success criteria**: All modules use new spec format, minimal boilerplate

---

### Phase 6: Documentation & Polish (Week 7)
**Goal**: Complete documentation and polish UX

**Tasks**:
1. Write comprehensive library documentation
2. Write module development guide (how to create modules)
3. Update README with new config examples
4. Create migration script (`just migrate-config`)
5. Add validation and helpful error messages
6. Performance testing and optimization
7. Create video walkthrough (optional)

**Files to create/modify**:
- `docs/libraries.md` (new)
- `docs/module-development.md` (new)
- `README.md` (update)
- `justfile` (add migrate-config command)

**Success criteria**: Clear documentation, easy onboarding for new users

---

### Phase 7: Advanced Features (Future)
**Goal**: Add advanced features inspired by LazyVim

**Tasks**:
1. Implement lazy loading support (load modules on-demand)
2. Add module "extras" system (optional feature bundles)
3. Create interactive module manager UI (`:WezMacsModules`)
4. Add hot reload support (reload config without restarting)
5. Create module marketplace/registry
6. Add telemetry and module usage analytics (opt-in)

**Files to create**: TBD based on features

**Success criteria**: Advanced features work, still backwards compatible

---

## 6. DETAILED FILE CHANGES

### 6.1 Files to Create (New)

| File Path | Purpose | Phase |
|-----------|---------|-------|
| `wezmacs/lib/config.lua` | Config utilities (merge, extend, get) | 1 |
| `wezmacs/lib/registry.lua` | Module registry and dependency resolution | 1 |
| `wezmacs/lib/keybindings.lua` | Declarative keybinding API | 1 |
| `wezmacs/lib/theme.lua` | Theme color access library | 1 |
| `wezmacs/lib/actions.lua` | Action helper utilities | 1 |
| `wezmacs/compat.lua` | Legacy config format compatibility | 4 |
| `wezmacs/modules/*/spec.lua` | Module specs (one per module, 15 total) | 2-5 |
| `examples/init-new-format.lua` | Example new config format | 4 |
| `docs/libraries.md` | Library documentation | 6 |
| `docs/module-development.md` | Module development guide | 6 |
| `docs/migration-guide.md` | Migration from old to new format | 4 |

---

### 6.2 Files to Modify (Refactor)

| File Path | Changes | Phase |
|-----------|---------|-------|
| `wezmacs/module.lua` | Refactor to use registry, specs, dependencies | 3 |
| `wezmacs/init.lua` | Support new loader, compat layer, libraries | 3-4 |
| `wezmacs/modules/*/init.lua` | Use specs and libraries (15 modules) | 2-5 |
| `wezmacs/modules/*/actions.lua` | Use action helpers library | 2-5 |
| `wezmacs/generate-config.lua` | Generate new format configs | 4 |
| `README.md` | Update examples and documentation | 6 |
| `justfile` | Add migration command | 6 |

---

### 6.3 Files to Keep Unchanged

| File Path | Reason |
|-----------|--------|
| `wezterm.lua` | Entry point, works with new init.lua |
| `wezmacs/utils/*.lua` | Low-level utilities (colors, split, etc.) still useful |
| `wezmacs/templates/*.lua` | Will be updated in Phase 6 but not critical path |

---

## 7. EXAMPLE MODULE CONVERSION

### Before: git module (old format)

```lua
-- wezmacs/modules/git/init.lua (OLD)
local wezterm = require("wezterm")
local actions = require("wezmacs.modules.git.actions")
local act = wezterm.action

local M = {}

M._NAME = "git"
M._CATEGORY = "integration"
M._DESCRIPTION = "Lazygit integration"
M._EXTERNAL_DEPS = { "lazygit", "delta" }

M._CONFIG = {
  leader_key = "g",
  leader_mod = "LEADER",
}

function M.apply_to_config(config)
  local mod = wezmacs.get_module(M._NAME)

  -- Create key table (25 lines of boilerplate)
  config.key_tables = config.key_tables or {}
  config.key_tables.git = {
    { key = "g", action = wezterm.action_callback(actions.lazygit_smart_split) },
    { key = "G", action = act.SpawnCommandInNewTab({ args = { "lazygit" } }) },
    { key = "d", action = wezterm.action_callback(actions.git_diff_smart_split) },
    { key = "l", action = wezterm.action_callback(actions.git_log_smart_split) },
    { key = "Escape", action = "PopKeyTable" },
  }

  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = mod.leader_key,
    mods = mod.leader_mod,
    action = act.ActivateKeyTable({
      name = "git",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
```

```lua
-- wezmacs/modules/git/actions.lua (OLD)
local split = require("wezmacs.utils.split")

local M = {}

function M.lazygit_smart_split(window, pane)
  split.smart_split(pane, { "lazygit", "-sm", "half" })
end

function M.lazygit_new_tab(window, pane)
  -- Handled inline in init.lua
end

function M.git_diff_smart_split(window, pane)
  local shell = os.getenv("SHELL") or "/bin/bash"
  split.smart_split(pane, {
    shell,
    "-lc",
    "git diff main 2>/dev/null || git diff master 2>/dev/null",
  })
end

function M.git_log_smart_split(window, pane)
  local shell = os.getenv("SHELL") or "/bin/bash"
  split.smart_split(pane, {
    shell,
    "-lc",
    "git log --oneline --graph --all -20",
  })
end

return M
```

---

### After: git module (new format)

```lua
-- wezmacs/modules/git/spec.lua (NEW)
return {
  name = "git",
  category = "integration",
  description = "Lazygit integration with smart splitting and git utilities",

  dependencies = {
    external = { "lazygit", "delta", "git" },
    modules = { "theme", "keybindings" },
  },

  opts = {
    leader_key = "g",
    leader_mod = "LEADER",

    features = {
      lazygit = {
        enabled = true,
        split_mode = "half",
      },
      git_diff = { enabled = true },
      git_log = {
        enabled = true,
        max_commits = 20,
      },
    },
  },

  keys = {
    {
      leader = "g",
      submenu = "git",
      bindings = {
        { key = "g", desc = "Open lazygit", action = "actions.lazygit_smart_split" },
        { key = "G", desc = "Lazygit in new tab", action = "actions.lazygit_new_tab" },
        { key = "d", desc = "Git diff", action = "actions.git_diff_smart_split" },
        { key = "l", desc = "Git log", action = "actions.git_log_smart_split" },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("git")
  end,

  priority = 50,
}
```

```lua
-- wezmacs/modules/git/init.lua (NEW - simplified)
local keybindings = require("wezmacs.lib.keybindings")
local actions = require("wezmacs.modules.git.actions")
local spec = require("wezmacs.modules.git.spec")

local M = {}

function M.apply_to_config(config, opts)
  -- Apply keybindings using library (1 line!)
  keybindings.apply_keys(config, spec, actions)

  -- Any other git-specific config
  -- (none needed for this module)
end

return M
```

```lua
-- wezmacs/modules/git/actions.lua (NEW - using libraries)
local action_lib = require("wezmacs.lib.actions")

local M = {}

-- Concise action definitions using helpers
M.lazygit_smart_split = action_lib.smart_split_action(
  { "lazygit" },
  { split_mode = "half" }
)

M.lazygit_new_tab = action_lib.new_tab_action({ "lazygit" })

M.git_diff_smart_split = action_lib.shell_command_action(
  "git diff main 2>/dev/null || git diff master 2>/dev/null",
  { smart_split = true }
)

M.git_log_smart_split = action_lib.shell_command_action(
  "git log --oneline --graph --all -20",
  { smart_split = true }
)

return M
```

**Line count comparison**:
- Old format: ~70 lines across 2 files
- New format: ~60 lines across 3 files (but much more readable and maintainable)
- Boilerplate reduced by ~60%

---

## 8. TESTING STRATEGY

### 8.1 Unit Tests

Create `tests/lib/` for library unit tests:

```lua
-- tests/lib/config_spec.lua
describe("config library", function()
  local config = require("wezmacs.lib.config")

  it("should deep merge tables", function()
    local base = { a = 1, b = { c = 2 } }
    local override = { b = { d = 3 }, e = 4 }
    local result = config.deep_merge(base, override)

    assert.are.equal(1, result.a)
    assert.are.equal(2, result.b.c)
    assert.are.equal(3, result.b.d)
    assert.are.equal(4, result.e)
  end)

  it("should extend nested paths", function()
    local tbl = { a = { b = 1 } }
    config.extend(tbl, "a.c", 2)
    assert.are.equal(2, tbl.a.c)
  end)
end)
```

### 8.2 Integration Tests

Test module loading with various configs:

```lua
-- tests/integration/loader_spec.lua
describe("module loader", function()
  it("should load modules in dependency order", function()
    local config = {
      modules = {
        git = { enabled = true },
        theme = { color_scheme = "Test" },
      }
    }

    local wezmacs = require("wezmacs.init")
    local result = wezmacs.setup(config)

    -- Theme should load before git (dependency)
    -- Verify by checking load order
  end)
end)
```

### 8.3 Manual Testing

1. Test with minimal config
2. Test with complex config (all modules enabled)
3. Test with custom modules
4. Test backward compatibility with old format
5. Test dependency validation (missing tools)
6. Test keybindings in WezTerm
7. Test theme color access from multiple modules

---

## 9. BACKWARD COMPATIBILITY

### 9.1 Legacy Config Support

Old config format will continue to work:

```lua
-- OLD FORMAT (still works)
return {
  core = { ... },
  theme = { color_scheme = "..." },
  git = { leader_key = "g" },
}
```

Automatically converted to:

```lua
-- NEW FORMAT (equivalent)
return {
  modules = {
    core = { ... },
    theme = { color_scheme = "..." },
    git = { leader_key = "g" },
  }
}
```

### 9.2 Deprecation Timeline

- **Phase 1-4**: Both formats supported
- **Phase 5**: Warning message for old format
- **v2.0**: Old format deprecated (still works with warning)
- **v3.0**: Old format removed

### 9.3 Migration Script

```bash
# Add to justfile
migrate-config:
    lua wezmacs/scripts/migrate-config.lua ~/.config/wezmacs/wezmacs.lua
```

Script converts old format to new format with comments.

---

## 10. SUCCESS METRICS

### Quantitative
- **Boilerplate reduction**: Target 60% reduction in module code
- **Module creation time**: From 30min to 10min for new modules
- **Config file size**: User configs should be 30-50% smaller
- **Load time**: No performance regression (< 100ms startup)

### Qualitative
- **Ease of use**: New users can create custom modules in < 15min
- **Documentation quality**: Comprehensive guides with examples
- **Maintainability**: Module code is self-documenting
- **Extensibility**: New patterns (extras, lazy loading) are feasible

---

## 11. RISKS & MITIGATIONS

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing configs | High | Compat layer, thorough testing, gradual rollout |
| Performance regression | Medium | Benchmark before/after, optimize registry lookups |
| Incomplete migration | Medium | Phased approach, both formats work side-by-side |
| Complex dependency bugs | High | Unit tests for dependency resolution, careful testing |
| User confusion | Medium | Clear migration guide, examples, video walkthrough |
| Library API instability | Low | Lock API in Phase 1, no breaking changes after |

---

## 12. OPEN QUESTIONS

1. **Auto-loading pattern**: Should we auto-load `~/.config/wezmacs/modules/*.lua` or require explicit imports?
   - **Recommendation**: Support both (explicit in init.lua, auto-load as opt-in)

2. **Module naming**: Keep flat structure or introduce categories (`integration.git`, `ui.theme`)?
   - **Recommendation**: Keep flat for simplicity, use category in spec

3. **Lazy loading**: Worth implementing in initial refactor or defer to Phase 7?
   - **Recommendation**: Defer to Phase 7, focus on ergonomics first

4. **Custom module path**: Support multiple custom module directories?
   - **Recommendation**: Support single `user.custom-modules` path initially

5. **Key description display**: Add which-key style menu display?
   - **Recommendation**: Phase 7 feature, requires WezTerm UI work

---

## 13. IMPLEMENTATION CONTEXT FOR ENGINEER AGENT

### Core Concepts to Understand

1. **Module Specs**: Declarative data structures that define module behavior, dependencies, config schema, and keybindings. Similar to LazyVim plugin specs.

2. **Registry System**: Central module registry that handles discovery, validation, and dependency resolution. Replaces hardcoded load order.

3. **Library Pattern**: Reusable utilities in `wezmacs.lib.*` that modules consume to reduce boilerplate. Think of it as a standard library for WezMacs modules.

4. **Deep Merge**: Config system where user overrides are deep-merged with module defaults at all levels. Existing implementation to be improved.

5. **Action Helpers**: Common patterns for WezTerm actions (smart splits, new tabs, shell commands) abstracted into reusable functions.

6. **Compatibility Layer**: Legacy config format detection and automatic migration to ensure zero breaking changes.

### Key Files to Reference

**Current Architecture**:
- `wezmacs/init.lua` - Current initialization logic
- `wezmacs/module.lua` - Current module loading
- `wezmacs/modules/git/init.lua` - Example of current module structure
- `wezmacs/modules/theme/init.lua` - Example of simple module
- `wezmacs/utils/keybindings.lua` - Current keybinding utilities

**LazyVim Research**:
- `.claude/research/2025-12-06-lazyvim-architecture.md` - Complete LazyVim analysis

### Implementation Guidelines

1. **Start with Libraries**: Build libraries first (Phase 1) so they can be tested independently before refactoring modules.

2. **Test Incrementally**: After each phase, ensure WezTerm can still load and all keybindings work.

3. **Keep Utils Separate**: Don't touch `wezmacs/utils/` - these are low-level helpers that remain useful.

4. **Preserve Behavior**: New implementation should produce identical WezTerm config output initially.

5. **Error Handling**: Add helpful error messages for common mistakes (missing dependencies, invalid specs, etc.).

6. **Lua Idioms**: Use metatables for lazy-loading where appropriate, avoid global pollution, prefer local functions.

### Testing Approach

1. **Unit test libraries**: Test config merging, registry logic, action helpers in isolation
2. **Integration test loader**: Test module loading with various configs and dependency graphs
3. **Manual test in WezTerm**: Launch WezTerm after each phase to verify behavior
4. **Compare outputs**: Use `wezterm show-keys` to verify keybinding changes match expectations

### Common Pitfalls to Avoid

1. **Circular dependencies**: Registry must detect and error on circular module deps
2. **Load order bugs**: Ensure theme loads before modules that use theme colors
3. **Shallow vs deep copy**: Be careful when copying tables (spec vs opts)
4. **String action resolution**: Handle both string paths ("actions.foo") and direct functions
5. **Escape key**: Always add Escape to exit key tables (often forgotten)

### Where to Get Help

- **WezTerm docs**: https://wezfurlong.org/wezterm/config/lua/
- **LazyVim patterns**: `.claude/research/2025-12-06-lazyvim-architecture.md`
- **Current codebase**: Grep for existing patterns before creating new ones
- **Lua stdlib**: Use `pcall` for safe requires, `ipairs`/`pairs` correctly

---

## 14. FUTURE ENHANCEMENTS (Post-Refactor)

### Module Extras System
Like LazyVim's extras, bundles of related modules:
```lua
{ import = "wezmacs.extras.lang.python" }  -- Python dev environment
{ import = "wezmacs.extras.ai.claude" }    -- AI workflow tools
```

### Interactive Module Manager
`:WezMacsModules` command to:
- Browse available modules
- Enable/disable modules
- Update module configs
- View module keybindings

### Hot Reload
Reload config without restarting WezTerm:
```lua
config.keys = {
  { key = "r", mods = "SUPER|SHIFT", action = wezterm.action.ReloadConfiguration },
}
```

### Module Marketplace
Central registry of community modules:
```bash
wezmacs install github-user/awesome-module
```

### Lazy Loading
Load modules on-demand:
```lua
{
  name = "docker",
  lazy = true,
  event = "SpawnTab",  -- Load when new tab spawned
}
```

### Telemetry (Opt-in)
Track module usage to improve defaults:
- Which modules are most popular?
- Which keybindings are actually used?
- Performance bottlenecks?

---

## CONCLUSION

This refactor brings WezMacs' configuration ergonomics up to par with modern frameworks like LazyVim while maintaining backward compatibility. The library system eliminates boilerplate, the spec format makes modules declarative and self-documenting, and the registry enables powerful features like dependency resolution and lazy loading.

The phased approach ensures stability throughout implementation, and the comprehensive testing strategy prevents regressions. The end result is a configuration system that's easier to use, easier to extend, and more maintainable long-term.

**Estimated Timeline**: 7 weeks for core implementation + documentation
**Estimated LOC**: ~2000 new lines (libraries + specs), ~1500 lines removed (boilerplate)
**Net Change**: +500 LOC, but 60% reduction in per-module code