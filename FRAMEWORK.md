# WezMacs Framework Architecture

This document describes the internal architecture of WezMacs for developers and advanced users.

## Design Philosophy

WezMacs uses a **pragmatic hybrid** approach:

- **From Doom Emacs**: Declarative module selection, feature flags, clear lifecycle phases
- **From LazyVim**: Plain Lua simplicity, straightforward module discovery, no complexity
- **From WezTerm**: Uses the proven `apply_to_config` pattern across the ecosystem

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
local M = {}

-- Metadata (for discovery and documentation)
M._NAME = "modulename"
M._CATEGORY = "category"  -- For docs only
M._DESCRIPTION = "What this does"
M._EXTERNAL_DEPS = { "tool1", "tool2" }

-- Configuration with defaults (includes features)
M._CONFIG = {
  -- Regular configuration
  leader_key = "g",
  leader_mod = "LEADER",

  -- Optional features (users must enable via `enabled = true`)
  smartsplit = {
    enabled = false,  -- Must be explicitly enabled
    config = {},
  },
  advanced = {
    enabled = false,
    config = {
      advanced_option = "default",
    },
    deps = { "smartsplit" },  -- Requires smartsplit to be enabled
  },
}

-- Apply phase (required) - modify WezTerm config
function M.apply_to_config(config)
  -- Get merged configuration from framework
  local mod = wezmacs.get_module("modulename")

  -- Check feature enabled with explicit check
  if mod.smartsplit and mod.smartsplit.enabled then
    -- Enable smart-split feature
  end

  -- Use mod for configuration values
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = mod.leader_key,
    mods = mod.leader_mod,
    action = wezterm.action.ActivateKeyTable({ name = "modulename" }),
  })

  -- Feature-specific config is at mod.feature_name.config
  if mod.advanced and mod.advanced.enabled then
    local advanced_config = mod.advanced.config
    -- Use advanced_config.advanced_option
  end
end

return M
```

### Module Loading

Modules are loaded in a single phase with framework-managed configuration:

**Apply Phase:**
- Called for each module after framework merges configuration
- Receives one parameter:
  - `config`: WezTerm config object (from config_builder())
- Uses `wezmacs.get_module(module_name)` to access merged configuration
- Modifies config object (add keybindings, set colors, register events, etc)
- Required - every module must define this
- Modules are stateless and have no initialization phase

**Configuration Merging:**
The framework handles configuration merging before modules run:
- User config from `config.lua` is deep-merged with module's `M._CONFIG` defaults
- Feature flags (with `enabled = true`) are processed along with regular config
- All merged config is accessible via global `wezmacs.get_module()` API

**Why Framework-Managed Config?**
- Eliminates duplicate config merging code in every module
- Modules are simpler and more focused on behavior
- Consistent configuration pattern across all modules
- Easier to test and maintain modules

### Categories (Documentation Only)

Categories organize modules by concern. They exist **only for documentation** - the code is completely flat:

- **UI**: Visual styling (appearance, tabbar, window)
- **Behavior**: User interactions (mouse, scrolling)
- **Editing**: Input modes (keybindings, selection)
- **Integration**: External integrations (plugins, multiplexing)
- **Workflows**: Feature-focused workflows (git, workspace, claude)

The flat `wezmacs/modules/` directory contains ALL modules regardless of category.

## Configuration Flow

```
wezterm.lua
  ↓
wezmacs.setup(config, opts)
  ↓
Load user modules (user/modules.lua or ~/.config/wezmacs/modules.lua)
  ↓
Load user config (user/config.lua or ~/.config/wezmacs/config.lua)
  ↓
For each enabled module:
  ├─ Load module file
  ├─ Extract user_config for module from config.lua
  ├─ Deep merge user_config with module._CONFIG defaults
  └─ Store merged config in global wezmacs table
  ↓
For each enabled module:
  ├─ Call apply_to_config(config)
  └─ Module accesses config via wezmacs.get_module(module_name)
  ↓
Return configured wezterm.config object
```

## API Contract

### Module Metadata

Every module should export these fields (for documentation and discovery):

```lua
M._NAME          -- string: module name (must match directory name)
M._CATEGORY      -- string: ui|behavior|editing|integration|workflows
M._DESCRIPTION   -- string: one-line description
M._EXTERNAL_DEPS -- table: list of external tools/dependencies
M._CONFIG        -- table: configuration defaults (includes regular config and features)
```

### Apply Function (Required)

```lua
function M.apply_to_config(config)
  -- config: WezTerm config object (from config_builder())

  -- Get merged configuration from framework
  local module_config = wezmacs.get_config("modulename")
  local enabled_flags = wezmacs.get_enabled_flags("modulename")

  -- Check for enabled feature flags
  if enabled_flags.smartsplit then
    -- Enable smart-split functionality
  end

  -- Use configuration values from module_config
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = module_config.leader_key,
    mods = module_config.leader_mod,
    action = wezterm.action.SomeAction(),
  })

  -- Feature-specific config is at config.features.feature_name
  if enabled_flags.advanced then
    local advanced_config = config.features.advanced
    -- Use advanced_config for feature-specific settings
  end
end
```

### Global WezMacs API

The framework provides a global `wezmacs` table with these functions:

```lua
-- Get merged configuration for a module
-- Returns table with values from config.lua merged with _CONFIG_SCHEMA defaults
local module_config = wezmacs.get_config("modulename")

-- Get enabled flags for a module
-- Returns table with flag_name = true for each enabled flag
local enabled_flags = wezmacs.get_enabled_flags("modulename")

-- Example usage in a module:
function M.apply_to_config(config)
  local cfg = wezmacs.get_config("git")
  local flags = wezmacs.get_enabled_flags("git")

  if flags.smartsplit then
    -- Use smartsplit feature
  end

  -- Use cfg.leader_key, cfg.leader_mod, etc.
end
```

## Module Loading

The module loader (`wezmacs/module.lua`) handles:

1. **Discovery**: Finding modules by name
2. **Loading**: Using `require()` to load module code
3. **Configuration Merging**: Merging user config with module defaults and processing features
4. **Application**: Running apply_to_config phases with framework-provided config access

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
  "appearance",
  "tabbar",
  "window",
  "mouse",
  "keybindings",

  -- Table with flags: enable optional features
  { name = "git", flags = { "smartsplit" } },
  { name = "workspace", flags = {} },

  "claude",
  "domains",
}
```

### config.lua - Module Configuration

Located at `user/config.lua` or `~/.config/wezmacs/config.lua`:

```lua
return {
  -- Per-module configuration values
  appearance = {
    theme = "Horizon Dark (Gogh)",
    font = "Iosevka Mono",
    font_size = 16,
  },

  keybindings = {
    leader_key = "Space",
    leader_mod = "CMD",
  },

  git = {
    leader_key = "g",
    leader_mod = "LEADER",
  },
}
```

**Configuration Pattern:**
- **modules.lua**: WHAT to load (module names + feature flags)
- **config.lua**: HOW to configure (settings for each module)

## Custom Modules

Users can create custom modules in `~/.config/wezterm/user/custom-modules/`:

```
user/custom-modules/
└── my-feature/
    ├── init.lua          # Module implementation
    └── README.md         # Documentation
```

Enable in modules.lua:
```lua
return {
  "appearance",
  { name = "my-feature", flags = {} },
}
```

Configure in config.lua:
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
- Merge with defaults
- Orchestrate module loading via `module.lua`
- Call init phases for all modules
- Call apply_to_config phases for all modules
- Apply user overrides

### wezmacs/module.lua

Module discovery and loading system.

Key function: `M.load_all(config, module_spec, flags, log)`

Responsibilities:
- Discover and load modules by name
- Run init() phases and store state
- Handle errors gracefully

### wezmacs/utils/keys.lua

Helper functions for keybinding modules:
- `mod_name()` - Convert modifier strings
- `chord()` - Create keybinding tuples
- `key_table()` - Create key tables with boilerplate
- `apply_to_keys()` - Safe key insertion
- `spawn_chord()` - Spawn command helpers
- `pane_nav()` - Pane navigation helpers
- `split_pane_action()` - Split pane helpers
- `tab_action()` - Tab management helpers

### wezmacs/utils/colors.lua

Color manipulation utilities:
- `parse_hex()` - Parse hex colors
- `to_hex()` - Convert RGB to hex
- `blend()` - Blend two colors
- `darken()` / `lighten()` - Adjust brightness
- `rgb_to_hsl()` / `hsl_to_rgb()` - Color space conversion
- `rotate_hue()` - Rotate hue
- `saturate()` - Adjust saturation
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
  get_config = function(name)
    return { leader_key = "g", leader_mod = "LEADER" }
  end,
  get_enabled_flags = function(name)
    return { smartsplit = true }
  end,
}

module.apply_to_config(config)

-- config now has module's settings applied
```

## Common Patterns

### Leader Key Submenus

```lua
config.key_tables = config.key_tables or {}
config.key_tables.my_menu = {
  { key = "a", action = wezterm.action.SomeAction() },
  { key = "b", action = wezterm.action.OtherAction() },
  { key = "Escape", action = "PopKeyTable" },
}

config.keys = config.keys or {}
table.insert(config.keys, {
  key = "m",
  mods = "LEADER",
  action = wezterm.action.ActivateKeyTable({
    name = "my_menu",
    one_shot = false,
    until_unknown = true,
  }),
})
```

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
