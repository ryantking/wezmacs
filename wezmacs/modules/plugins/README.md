# plugins module

Integrates external WezTerm plugins for enhanced functionality.

## Features

- **Smart Workspace Switcher**: Fuzzy search and switch between workspaces
- **Workspace Formatting**: Custom display with nerd font icons and colors
- **Workspace Status**: Shows active workspace basename in window title bar
- **Quick Domains**: SSH/Docker/Kubernetes domain management
- **Domain Keybindings**: ALT+SHIFT+t to attach, CTRL+ALT+- to hsplit, CTRL+SHIFT+ALT+_ to vsplit

## Configuration

```lua
flags = {
  integration = {
    plugins = {}  -- No configurable flags currently
  }
}
```

## Plugins Included

### Smart Workspace Switcher
- **GitHub**: https://github.com/MLFlexer/smart_workspace_switcher.wezterm
- **Function**: Fuzzy search across workspaces
- **Keybinding**: LEADER+s (from workflows/workspace module)
- **Status**: Shows workspace name with 󱂬 icon in colored format

### Quick Domains
- **GitHub**: https://github.com/DavidRR-F/quick_domains.wezterm
- **Functions**:
  - `ALT+SHIFT+t`: Attach to remote domain
  - `CTRL+SHIFT+ALT+_`: Vertical split to domain
  - `CTRL+ALT+-`: Horizontal split to domain
- **Auto-execution**:
  - SSH: Ignored (manual control)
  - Docker: Enabled (auto-execute)
  - Kubernetes: Ignored (manual control)

## Installation

Plugins are automatically installed on first use. No manual installation needed.

## Workspace Events

The module registers event handlers for:
- `smart_workspace_switcher.workspace_switcher.created` - Updates status bar when workspace created
- `smart_workspace_switcher.workspace_switcher.chosen` - Updates status bar when workspace switched

## External Dependencies

- **smart_workspace_switcher**: Auto-installed via WezTerm plugin system
- **quick_domains**: Auto-installed via WezTerm plugin system

## Keybindings

See related modules:
- `workflows/workspace` - Workspace switching
- `editing/keybindings` - Other keybindings
