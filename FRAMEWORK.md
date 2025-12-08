# WezMacs Framework Architecture

This document describes the internal architecture of WezMacs for developers and advanced users.

## Design Philosophy

WezMacs uses a **pragmatic hybrid** approach:

- **From Doom Emacs**: Declarative module selection, modular architecture
- **From LazyVim**: Plain Lua simplicity, straightforward module discovery, no complexity
- **From WezTerm**: Direct config modification pattern

This balances power with simplicity: enough structure to keep configs organized, but simple enough that anyone can understand it.

## Core Concepts

### Modules

Each module is a self-contained unit providing one feature or cohesive set of features.

**Module Anatomy:**
```
wezmacs/modules/modulename/
├── init.lua        # Module implementation
└── README.md       # User documentation
```

**Module Structure:**
```lua
local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
  name = "modulename",
  description = "What this does",
  deps = { "tool1", "tool2" },

  opts = {
    some_option = "default_value",
    another_option = 42,
  },

  keys = function(opts)
    return {
      { key = "g", mods = "LEADER", action = act.SomeAction(), desc = "action" },
      LEADER = {
        g = {
          { key = "g", action = act.OtherAction(), desc = "nested-action" },
        },
      },
    }
  end,

  setup = function(config, opts)
    -- Modify config based on opts
    config.some_setting = opts.some_option
  end,
}
```

### Module Loading

Modules are loaded in phases:

**Options Phase:**
- Module defines `opts` (table or function returning table) with defaults
- User can override via `modules.lua` table entry: `{ name = "module", opts = { ... } }`
- Framework merges user opts with module defaults
- Merged opts passed to `keys` function and `setup` function

**Keys Phase:**
- Module defines `keys` function (or table) that receives merged `opts`
- Returns mixed list/map format: list items are direct bindings, string keys create nested key tables
- Framework processes via `wezmacs.keys.map()` to convert to WezTerm format

**Setup Phase:**
- Module defines `setup` function that receives `config` and merged `opts`
- Modifies WezTerm config object directly
- Used for non-keybinding configuration (colors, fonts, events, etc)

**Why This Pattern?**
- Clear separation: opts for configuration, keys for keybindings, setup for config modification
- Options are merged automatically by framework
- Keybindings use consistent format across all modules
- Modules are simple and focused

### Categories (Documentation Only)

Categories organize modules by concern. They exist **only for documentation** - the code is completely flat:

- **Core**: Terminal settings (term, tabs, window, mouse)
- **Keybindings**: Keybinding modules (app)
- **Integration**: External integrations (mux, git, agent, app, edit)

The flat `wezmacs/modules/` directory contains ALL modules regardless of category.

## Configuration Flow

```
wezterm.lua
  ↓
Load wezmacs framework
  ↓
Load user config (~/.config/wezmacs/config.lua)
  ↓
Load user modules (~/.config/wezmacs/modules.lua)
  ↓
For each module entry:
  ├─ Load module file
  ├─ Get default opts (from module.opts)
  ├─ Merge user opts (from modules.lua entry) with defaults
  ├─ Call module.setup(config, merged_opts)
  ├─ Call module.keys(merged_opts) to get keybindings
  └─ Apply keybindings via wezmacs.keys.map()
  ↓
Return configured wezterm.config object
```

## API Contract

### Module Fields

Every module should export these fields:

```lua
name          -- string: module name (must match directory name)
description   -- string: one-line description
deps          -- table: list of external tool dependencies
opts          -- table or function: configuration defaults
keys          -- table or function(opts): keybindings
setup         -- function(config, opts): modify WezTerm config
```

### Module Functions

**opts** (optional):
```lua
opts = {
  some_option = "default",
  another_option = 42,
}

-- Or function that returns table:
opts = function()
  return {
    dynamic_option = os.getenv("VAR") or "default",
  }
end
```

**keys** (optional):
```lua
keys = function(opts)
  return {
    -- List items are direct keybindings
    { key = "r", mods = "CTRL", action = act.Reload, desc = "reload" },
    -- String keys create nested key tables
    LEADER = {
      g = {
        { key = "g", action = act.SomeAction(), desc = "action" },
      },
    },
  }
end
```

**setup** (optional):
```lua
setup = function(config, opts)
  -- Modify config based on opts
  config.color_scheme = opts.color_scheme
  config.font = wezterm.font(opts.font)
end
```

### Global WezMacs API

The framework provides a global `wezmacs` table:

```lua
wezmacs.config          -- Global configuration (from config.lua)
wezmacs.color_scheme()  -- Lazy-loaded color scheme
wezmacs.keys.map()      -- Keybinding mapper
wezmacs.action          -- Custom action helpers (SmartSplit, NewTab, etc)
```

## Module Loading

The module loader (`wezmacs/module.lua`) handles:

1. **Discovery**: Finding modules by name
2. **Loading**: Using `require()` to load module code
3. **Configuration Merging**: Merging user opts with module defaults
4. **Application**: Running setup() and processing keys() for each module

**Module Search Order:**
1. `wezmacs.modules.modulename` (built-in modules)
2. `user.custom-modules.modulename` (user custom modules)
3. Error if not found

## User Configuration

WezMacs uses two configuration files:

### modules.lua - Module Selection

Located at `user/modules.lua` or `~/.config/wezmacs/modules.lua`:

```lua
return {
  -- Simple string: load with defaults
  "term",
  "tabs",
  "window",
  "mouse",
  "app",
  "keys",

  -- Table with opts: override module options
  { name = "git", opts = { diff_branches = { "main", "develop" } } },

  "agent",
  "mux",
  "edit",
}
```

### config.lua - Module Configuration

Located at `user/config.lua` or `~/.config/wezmacs/config.lua`:

```lua
return {
  -- Per-module configuration values (optional, can also use opts in modules.lua)
  term = {
    color_scheme = "Horizon Dark (Gogh)",
    font = "Iosevka Mono",
    font_size = 16,
  },

  app = {
    leader_key = "Space",
    leader_mod = "CMD",
  },

  git = {
    diff_branches = { "main", "master" },
  },
}
```

**Configuration Pattern:**
- **modules.lua**: WHAT to load (module names + feature flags)
- **config.lua**: HOW to configure (settings for each module)

## Custom Modules

Users can create custom modules in `~/.config/wezmacs/custom-modules/`:

```
~/.config/wezmacs/custom-modules/
└── my-feature/
    ├── init.lua          # Module implementation
    └── README.md         # Documentation (optional)
```

Enable in modules.lua:
```lua
return {
  "term",
  { name = "my-feature", opts = { some_option = "value" } },
}
```

Or configure in config.lua:
```lua
return {
  ["my-feature"] = {
    some_option = "value",
  },
}
```

## Framework Code

### wezmacs/init.lua

Main entry point. Exports `M.setup(config, opts)` function.

Responsibilities:
- Load user configuration
- Orchestrate module loading via `module.lua`
- Merge user opts with module defaults
- Call setup() for each module
- Process keys() for each module

### wezmacs/module.lua

Module discovery and loading system.

Key function: `M.load_all(config, module_spec, flags, log)`

Responsibilities:
- Discover and load modules by name
- Run init() phases and store state
- Handle errors gracefully

### wezmacs/keys.lua

Keybinding conversion system:
- `map(config, key_map, module_name)` - Convert mixed list/map format to WezTerm keybindings
- Handles LEADER keybindings and nested key tables
- Processes list items as direct bindings, string keys as nested tables

### wezmacs/action.lua

Custom action helpers:
- `SmartSplit(command)` - Auto-orient split based on window aspect ratio
- `NewTab(command)` - Spawn command in new tab
- `NewWindow(command)` - Spawn command in new window
- `invert()` / `complement()` - Advanced color ops

## Design Patterns

### Safe Table Appending

Always check table exists before appending:

```lua
config.keys = config.keys or {}
table.insert(config.keys, binding)

config.key_tables = config.key_tables or {}
config.key_tables.my_table = { ... }
```

### Action Callbacks

For complex actions, use wezterm.action_callback:

```lua
config.keys = config.keys or {}
table.insert(config.keys, {
  key = "a",
  mods = "CMD",
  action = wezterm.action_callback(function(window, pane)
    local dims = pane:get_dimensions()
    -- Complex logic here
  end),
})
```

### Event Handlers

Register events (can be called multiple times - handlers stack):

```lua
wezterm.on("event-name", function(window, pane, ...)
  -- Handle event
end)
```

### Conditional Logic

Only add features if dependencies available:

```lua
local has_feature = wezterm.run_child_process({ "which", "tool" })
if has_feature then
  -- Add keybindings for tool
end
```

## Performance Considerations

- **No lazy-loading**: Modules load instantly (WezTerm startup is already fast)
- **Stateless loading**: Each module load is independent
- **Simple require**: No caching issues or side effects
- **No external dependencies**: Framework uses only Lua stdlib + wezterm

## Testing Modules

You can test a module independently:

```lua
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local module = require("wezmacs.modules.modulename")

-- Set up global wezmacs API for testing
_G.wezmacs = {
  config = { term_mod = "CTRL|SHIFT", gui_mod = "SUPER" },
  keys = { map = function() end },
  action = require("wezmacs.action"),
}

local opts = module.opts or (type(module.opts) == "function" and module.opts() or {})
if module.setup then
  module.setup(config, opts)
end
if module.keys then
  local keys = type(module.keys) == "function" and module.keys(opts) or module.keys
  -- Process keys...
end

-- config now has module's settings applied
```

## Common Patterns

### Leader Key Submenus

Using the new keybinding format:

```lua
keys = function(opts)
  return {
    LEADER = {
      m = {
        { key = "a", action = act.SomeAction(), desc = "action-a" },
        { key = "b", action = act.OtherAction(), desc = "action-b" },
      },
    },
  }
end
```

The framework automatically creates the key table and activation binding.

### Smart Orientation

Split panes based on window aspect ratio:

```lua
local function my_action(window, pane)
  local dims = pane:get_dimensions()
  local direction = dims.pixel_height > dims.pixel_width and "Bottom" or "Right"
  pane:split({
    direction = direction,
    size = 0.5,
    args = { "command" },
  })
end
```

### Toast Notifications

Provide user feedback:

```lua
window:toast_notification("WezMacs", "Operation completed", nil, 3000)
```

### Working Directory Detection

Get current working directory:

```lua
local cwd_uri = pane:get_current_working_dir()
local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
```

## Extending WezMacs

To add a new built-in module:

1. Create `wezmacs/modules/modulename/`
2. Write `init.lua` with metadata and phases
3. Write `README.md` with features and dependencies
4. Document in main README.md
5. Update examples/

To use as a user:

1. Create `user/custom-modules/modulename/`
2. Write `init.lua` with metadata and phases
3. Write optional README.md
4. Enable in `user/config.lua`

## FAQ

**Q: Can modules depend on other modules?**
A: Not directly. Modules are independent units. Share state via flags or communicate through wezterm events.

**Q: Can I override a built-in module?**
A: Yes! Create a module with the same name in `user/custom-modules/` and it will be found first.

**Q: What if I don't want to use modules?**
A: You can still use WezTerm directly - just avoid loading wezmacs and write your own config.

**Q: How do I debug module loading?**
A: Use `log_level = "debug"` in wezmacs.setup() call in wezterm.lua. Check WezTerm logs.

**Q: Can I use external Lua libraries?**
A: Yes, but you'll need to bundle them or ensure they're in Lua's package.path.
