# Research: WezTerm Configuration Frameworks and Lua Module Patterns
Date: 2025-11-30
Focus: Best practices for building a modular wezterm configuration framework with Lua
Agent: researcher

## Summary
The wezterm ecosystem uses modular Lua configurations with an `apply_to_config` convention pattern. Popular configurations organize code into directories by concern (config/, events/, utils/, colors/) and follow Lua best practices of returning local tables from modules. The official plugin system provides a standard architecture for extensible configurations.

## Key Findings

### Existing WezTerm Configuration Frameworks
- **No major "distributions" exist** - instead, there are well-structured individual configurations shared on GitHub
- **Most popular patterns**: [KevinSilvester/wezterm-config](https://github.com/KevinSilvester/wezterm-config) and [sravioli/wezterm](https://github.com/sravioli/wezterm) demonstrate mature modular architectures
- **[awesome-wezterm](https://github.com/michaelbrusegard/awesome-wezterm)** curates 40+ plugins across 9 categories (AI, keybindings, session management, tab bars, themes, utilities)
- **Plugin ecosystem** focuses on: workspace management, tmux-like keybindings, Neovim integration, fuzzy finding, and developer workflows

### WezTerm-Specific Configuration Patterns

**File Location**
- Simple: `$HOME/.wezterm.lua`
- Complex/multi-file: `$XDG_CONFIG_HOME/wezterm/wezterm.lua` or `~/.config/wezterm/wezterm.lua`

**Official Convention: `apply_to_config` Pattern**
```lua
-- In helper module: ~/.config/wezterm/helpers.lua
local M = {}

function M.apply_to_config(config)
  config.some_option = "value"
  -- configure here
end

return M

-- In main wezterm.lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local helpers = require 'helpers'
helpers.apply_to_config(config)
return config
```

**Package Path**
WezTerm configures `package.path` to search:
1. `wezterm_modules/` (Windows portable mode)
2. `~/.config/wezterm/`
3. `~/.wezterm/`
4. System Lua paths

This allows `require 'modulename'` to find modules in your config directory automatically.

**Plugin System**
- Plugins are Git repositories with `plugin/init.lua` that exports `apply_to_config(config, opts)`
- Loaded via `wezterm.plugin.require('https://github.com/owner/repo')`
- Cloned to runtime directory under `plugins/NAME` on first use
- Update all with `wezterm.plugin.update_all()`

### Lua Module System Best Practices

**Standard Module Pattern (Recommended by Lua Committee)**
```lua
local M = {}

-- Private functions/variables (not exported)
local function private_helper()
  -- implementation
end

-- Public API
function M.public_function()
  private_helper()
end

-- Metadata (recommended)
M._VERSION = "1.0.0"
M._DESCRIPTION = "Module description"
M._LICENSE = "MIT"

return M
```

**Key Principles**
- **Return local table** - modern best practice, avoids global namespace pollution
- **Avoid `module()` function** - deprecated, modifies global environment
- **No global variables** - define everything in module table or as locals
- **Avoid side effects** - modules should not execute code on require, only define functions
- **Encapsulation** - separate public API (in returned table) from private implementation (local functions)

**Module Organization**
- Each module should have clear, single purpose
- Use version control to track changes
- Use luacheck for linting (seen in KevinSilvester config)
- Add `.stylua.toml` for consistent formatting

**Package Path Configuration**
- `package.path` contains semicolon-separated patterns with `?` placeholder
- `?` is replaced with module name during search
- Modify via: `package.path = package.path .. ';./mydir/?.lua'`
- Double semicolon `;;` means "append to existing path"
- Set `LUA_PATH` environment variable to add paths globally

### Popular Configuration Architectures

**KevinSilvester/wezterm-config Structure**
```
.
├── config/          # Core configuration (appearance, domains, launch)
├── colors/          # Color schemes
├── events/          # Event handlers
├── utils/           # Utilities (background selector, GPU detection)
├── backdrops/       # Background images
└── wezterm.lua      # Main entry point
```

**sravioli/wezterm Structure**
```
.
├── config/          # Core settings
├── events/          # Event handlers
├── mappings/        # Keybindings with human-readable format
│   └── default.lua  # Keybinding definitions
├── picker/          # Custom pickers (class-based)
├── utils/           # Utilities
│   └── fn.lua       # Functional helpers (key.map())
└── wezterm.lua      # Entry point
```

**Common Patterns**
1. **Separation by concern** - config/, events/, utils/, colors/, mappings/
2. **Utility abstraction** - complex operations in utils/ directory
3. **Class-based helpers** - for reusable UI components (pickers)
4. **Functional composition** - helper functions for reducing boilerplate
5. **Mode-based organization** - different keybinding tables for different modes
6. **Configuration-as-data** - keybindings stored as tables, programmatically transformed

### Plugin Ecosystem Patterns

**Categories of Functionality**
- **AI**: Natural language command generation
- **Keybinding**: Modal interfaces, tmux-style bindings
- **Neovim Integration**: Seamless pane navigation
- **Session Management**: Workspace switchers with fuzzy finding, Git integration
- **Tab Bar**: Customizable rendering with status indicators
- **Themes**: Color scheme implementations
- **Utility**: Command broadcasting, Unicode insertion, error parsing

**Common Plugin Patterns**
- Leverage external tools (fd, zoxide) for enhanced functionality
- Support modal keybinding schemes
- Focus on developer workflow enhancement
- Terminal multiplexing capabilities

## Detailed Analysis

### Configuration Architecture Decision Points

**1. Entry Point Strategy**
The main `wezterm.lua` should be minimal - just requiring modules and calling their `apply_to_config` functions. This keeps the entry point clean and makes it easy to enable/disable features.

**2. Module Organization Philosophy**
Two viable approaches emerged:
- **By Feature Type** (config/, events/, colors/, utils/) - KevinSilvester's approach
- **By Concern with Deeper Nesting** (mappings/default.lua, picker/, utils/fn.lua) - sravioli's approach

The first is simpler and more discoverable. The second is better for very large configs with many sub-features per category.

**3. Configuration Flexibility**
Both successful configs use the `apply_to_config` pattern but with different philosophies:
- **Imperative**: Module directly modifies config object
- **Declarative**: Module returns data that main file applies to config

The imperative approach is more common and aligns with wezterm's official plugin convention.

**4. Code Quality Tooling**
Production configurations include:
- `.luacheckrc` - for static analysis
- `.stylua.toml` - for code formatting
- `.luarc.json` - for LSP configuration

This enables consistent code quality and better IDE support.

### Lua Module System Deep Dive

**Why Return Local Tables?**
1. **Namespace safety** - no global pollution
2. **Explicit exports** - clear API surface
3. **Multiple instances** - can require module multiple times with separate state if needed
4. **Composability** - modules can require other modules without conflicts

**Module Loading Process**
1. `require 'modulename'` is called
2. Lua checks `package.preload[modulename]` for pre-loaded function
3. If not found, searches `package.path` patterns, replacing `?` with module name
4. Loads first matching file
5. Executes file contents
6. Caches return value in `package.loaded[modulename]`
7. Returns cached value on subsequent requires

**Critical Best Practice: Avoid Side Effects**
WezTerm may evaluate config multiple times during startup and reloads. Modules should NOT:
- Spawn processes
- Write files
- Make network calls
- Modify global state

Instead, defer side effects to event handlers or explicit function calls.

### WezTerm-Specific Considerations

**Config Builder Pattern**
```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
-- config builder provides validation and helpful error messages
-- attempting to set invalid options generates warnings
config.invalid_option = true  -- logs warning instead of silently failing
return config
```

**Hot Reload Support**
WezTerm automatically reloads configuration when files change. Design considerations:
- Keep module logic stateless
- Use event handlers for stateful operations
- Don't cache values that should update on reload

**Event System**
Events should be in separate modules that register handlers:
```lua
local wezterm = require 'wezterm'
local M = {}

function M.apply_to_config(config)
  wezterm.on('update-status', function(window, pane)
    -- handler implementation
  end)
end

return M
```

## Applicable Patterns for Wezmacs

Based on this research, recommended patterns:

**1. Directory Structure**
```
~/.config/wezterm/
├── wezterm.lua           # Minimal entry point
├── wezmacs/              # Core framework
│   ├── init.lua          # Framework initialization
│   ├── config/           # Configuration modules
│   ├── keymaps/          # Keybinding definitions
│   ├── events/           # Event handlers
│   ├── plugins/          # Plugin system
│   └── utils/            # Utilities
└── lua/                  # User configuration
    └── user/
        ├── init.lua
        ├── config.lua
        └── keymaps.lua
```

**2. Module Pattern**
```lua
-- All wezmacs modules follow this pattern
local M = {}

M._VERSION = "0.1.0"

function M.apply_to_config(config, opts)
  opts = opts or {}
  -- configure based on opts
end

return M
```

**3. User Configuration Loading**
```lua
-- In wezmacs/init.lua
local M = {}

function M.setup(user_config_path)
  user_config_path = user_config_path or 'user'

  local ok, user_config = pcall(require, user_config_path)
  if not ok then
    -- Handle missing user config gracefully
    return {}
  end

  return user_config
end

return M
```

**4. Plugin System**
Follow wezterm's plugin convention but with wezmacs namespace:
```lua
-- Plugin at ~/.config/wezterm/wezmacs/plugins/example/init.lua
local M = {}

function M.apply_to_config(config, opts)
  -- plugin implementation
end

return M
```

**5. Keybinding System**
Use declarative keybinding tables with functional composition:
```lua
-- Define bindings as data
local keymaps = {
  { mods = 'LEADER', key = 'c', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { mods = 'LEADER', key = '|', action = wezterm.action.SplitHorizontal },
}

-- Transform to wezterm format
local function apply_keymaps(config, keymaps)
  config.keys = config.keys or {}
  for _, keymap in ipairs(keymaps) do
    table.insert(config.keys, keymap)
  end
end
```

**6. Error Handling**
```lua
local function safe_require(module_name)
  local ok, result = pcall(require, module_name)
  if not ok then
    wezterm.log_error('Failed to load module: ' .. module_name .. ': ' .. result)
    return nil
  end
  return result
end
```

**7. Version Compatibility**
```lua
local M = {}

M.MIN_WEZTERM_VERSION = '20230712-072601-f4abf8fd'

function M.check_version()
  local version = wezterm.version
  -- Compare versions and warn if incompatible
end
```

## Sources

### WezTerm Configuration Examples
- [KevinSilvester/wezterm-config](https://github.com/KevinSilvester/wezterm-config)
- [sravioli/wezterm](https://github.com/sravioli/wezterm)
- [awesome-wezterm plugin collection](https://github.com/michaelbrusegard/awesome-wezterm)
- [wezterm-config topic on GitHub](https://github.com/topics/wezterm-config)

### Official WezTerm Documentation
- [WezTerm Configuration Files](https://wezterm.org/config/files.html)
- [WezTerm Plugins](https://wezterm.org/config/plugins.html)
- [WezTerm Config Options](https://wezterm.org/config/lua/config/index.html)
- [WezTerm Config Builder](https://wezterm.org/config/lua/wezterm/config_builder.html)
- [Configuration System on DeepWiki](https://deepwiki.com/wezterm/wezterm/2.1-configuration-system)

### Lua Module Best Practices
- [Mastering Lua Modules and Packages](https://softwarepatternslexicon.com/lua/lua-programming-fundamentals/modules-and-packages/)
- [Lua Modules Tutorial](http://lua-users.org/wiki/ModulesTutorial)
- [Lua Module Pattern - Return Local Table](http://kiki.to/blog/2014/03/31/rule-2-return-a-local-table/)
- [Recommended Module Structure](https://help.interfaceware.com/v6/recommended-module-structure)
- [Lua Modules Best Practice Discussion](https://llllllll.co/t/lua-modules-best-practice-var-function-scope/31699)
- [Lua Modules - Tutorialspoint](https://www.tutorialspoint.com/lua/lua_modules.htm)

### Lua Package System
- [Modules - Lua Cookbook](https://stevedonovan.github.io/lua-cookbook/topics/06-modules.md.html)
- [Mastering Lua Module Loading](https://lualibrary.com/lua-module-loading)
- [Programming in Lua: Modules](https://www.lua.org/pil/8.1.html)
- [Lua 5.3 Reference Manual - Modules](https://q-syshelp.qsc.com/q-sys_7.0/Content/Control_Scripting/Lua_5.3_Reference_Manual/Standard_Libraries/2_-_Modules.htm)

### Configuration Guides
- [WezTerm Config Guide 2024](https://gilbertsanchez.com/posts/my-terminal-wezterm/)
- [Configuring WezTerm](https://www.sharpwriting.net/project/configuring-wezterm/)
- [Splitting Configuration Files Discussion](https://github.com/wezterm/wezterm/discussions/914)

## Confidence Level
**High** - Based on official documentation, multiple production configuration examples, and established Lua community best practices. The `apply_to_config` pattern is the official convention, and the module architecture is well-established across the ecosystem.

## Related Questions
- How should wezmacs handle backward compatibility with wezterm version updates?
- What testing strategy works best for Lua configuration frameworks?
- Should wezmacs support both imperative and declarative configuration styles?
- How can wezmacs integrate with existing wezterm plugins from awesome-wezterm?
- What performance considerations exist for large modular configurations?
