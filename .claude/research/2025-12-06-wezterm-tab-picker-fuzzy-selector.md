# Research: WezTerm Tab Picker and Fuzzy Selector

Date: 2025-12-06
Focus: Does WezTerm have native tab picker/selector with fuzzy search capabilities?
Agent: researcher

## Summary

WezTerm has robust native tab selection with fuzzy search support through two complementary actions: `ShowTabNavigator` (simple tab list) and `ShowLauncherArgs` (flexible launcher with fuzzy filtering). Both features are fully implemented and available in nightly/recent builds.

## Key Findings

1. **Native Tab Picker Exists**: `ShowTabNavigator` provides a dedicated tab selection UI [Official Docs](https://wezterm.org/config/lua/keyassignment/ShowTabNavigator.html)
2. **Fuzzy Search Available**: The `FUZZY` flag enables fuzzy matching mode in the launcher [ShowLauncherArgs Docs](https://wezterm.org/config/lua/keyassignment/ShowLauncherArgs.html)
3. **Feature is Mature**: Originally requested in Issue #664 (April 2021), fully implemented and closed [GitHub Issue](https://github.com/wezterm/wezterm/issues/664)
4. **Active Tab Pre-selected**: Recent improvement (PR #6320) ensures current tab is selected by default in ShowTabNavigator

## Detailed Analysis

### ShowTabNavigator

The simplest way to get a tab picker. Displays a list of all tabs in the current window and allows selection.

**Configuration:**
```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.keys = {
  { key = 'F9', mods = 'ALT', action = wezterm.action.ShowTabNavigator },
}

return config
```

**Behavior:**
- Displays a visual list of all tabs
- The currently active tab is pre-selected
- Useful when tab bar is hidden
- Simple UI, no fuzzy matching built-in

### ShowLauncherArgs (Recommended for Fuzzy)

More powerful action that can show tabs with fuzzy filtering capability.

**Available Flags:**
| Flag | Description |
|------|-------------|
| `FUZZY` | Activates fuzzy-only filtering mode |
| `TABS` | Shows current window's tabs |
| `LAUNCH_MENU_ITEMS` | Shows configured launch menu items |
| `DOMAINS` | Lists multiplexing domains |
| `KEY_ASSIGNMENTS` | Shows key assignment items |
| `WORKSPACES` | Displays available workspaces |
| `COMMANDS` | Shows default commands |

**Configuration with Fuzzy Tab Selection:**
```lua
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.keys = {
  -- Fuzzy tab selector
  { key = '9', mods = 'ALT', action = act.ShowLauncherArgs { flags = 'FUZZY|TABS' } },

  -- Fuzzy with tabs and workspaces
  { key = 't', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|TABS|WORKSPACES' } },

  -- Full launcher with fuzzy
  { key = 'Space', mods = 'CTRL', action = act.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS|TABS' } },
}

return config
```

**Additional ShowLauncherArgs Options:**
```lua
config.keys = {
  {
    key = 'l',
    mods = 'LEADER',
    action = act.ShowLauncherArgs {
      flags = 'FUZZY|TABS|WORKSPACES',
      title = 'Select Tab or Workspace',  -- Custom title
    },
  },
}
```

### Navigation Controls

When in the launcher/tab navigator:
- **Type text**: Start fuzzy matching
- **CTRL-N/CTRL-P**: Navigate up/down
- **CTRL-J/CTRL-K**: Navigate up/down (vim-style)
- **Enter**: Select item
- **CTRL-[** or **Escape**: Close launcher
- **/**: Enter fuzzy mode (if not already in FUZZY mode)

### Launcher Menu Customization

You can customize what appears in the launcher:

```lua
config.launch_menu = {
  {
    label = 'Bash Shell',
    args = { 'bash', '-l' },
  },
  {
    label = 'System Monitor',
    args = { 'top' },
  },
  {
    label = 'SSH to Server',
    args = { 'ssh', 'user@server.example.com' },
    -- Optional: set working directory
    -- cwd = '/home/user',
  },
}
```

### Appearance Customization

Customize launcher label colors:
```lua
config.colors = {
  -- Launcher menu labels
  launcher_label_fg = '#cccccc',
  launcher_label_bg = '#1a1a1a',
}
```

## Applicable Patterns for WezMacs

For the WezMacs framework, consider implementing a `picker` or `selector` module:

```lua
-- wezmacs/modules/picker/init.lua
local M = {}

M.spec = {
  name = "picker",
  desc = "Tab and workspace picker with fuzzy search",
  category = "navigation",
}

function M.setup(config)
  local wezterm = require 'wezterm'
  local act = wezterm.action

  return {
    keys = {
      -- Quick tab picker
      { key = 't', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|TABS' } },

      -- Full navigator with workspaces
      { key = 'p', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs {
          flags = 'FUZZY|TABS|WORKSPACES|COMMANDS',
          title = 'WezMacs Navigator',
        }
      },

      -- Simple tab navigator (fallback)
      { key = 'Tab', mods = 'CTRL', action = act.ShowTabNavigator },
    },
  }
end

return M
```

## Limitations

1. **Nightly Requirement**: Some features require nightly builds (ShowTabNavigator marked as nightly-only in some docs)
2. **No Pane Picker**: Native pane selection fuzzy picker requires using `PaneSelect` action instead
3. **Single Window Scope**: Tab navigator shows tabs from current window only

## Related Actions

- `ShowTabNavigator` - Simple tab list
- `ShowLauncherArgs { flags = 'FUZZY|TABS' }` - Fuzzy tab picker
- `ShowLauncher` - Default launcher (same as ShowLauncherArgs with default flags)
- `PaneSelect` - For pane selection
- `ActivateTab(n)` - Direct tab activation by index
- `ActivateTabRelative(n)` - Relative tab navigation

## Sources

- [ShowTabNavigator - Official Docs](https://wezterm.org/config/lua/keyassignment/ShowTabNavigator.html)
- [ShowLauncherArgs - Official Docs](https://wezterm.org/config/lua/keyassignment/ShowLauncherArgs.html)
- [Launcher Menu Configuration](https://wezterm.org/config/launch.html)
- [Issue #664 - Fuzzy Find Feature Request](https://github.com/wezterm/wezterm/issues/664)
- [PR #6320 - Active Tab Selection](https://github.com/wez/wezterm/pull/6320)
- [Context7 WezTerm Documentation](https://github.com/wezterm/wezterm)

## Confidence Level

**High** - Information sourced from official WezTerm documentation and confirmed via multiple sources including GitHub issues, pull requests, and Context7 API documentation.

## Related Questions

- How to customize the launcher menu appearance (colors, fonts)?
- Can the launcher be extended with custom actions/commands?
- How does `PaneSelect` work for pane-level fuzzy selection?
- Is there a way to show tabs from all windows, not just the current one?
