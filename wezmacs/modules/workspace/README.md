# workspace module

Provides workspace switching and management with fuzzy search and Claude workspace support.

## Configuration

```lua
flags = {
  workflows = {
    workspace = {
      leader_key = "s",        -- Workspace switcher key
      leader_mod = "LEADER"    -- Modifier for workspace menu
    }
  }
}
```

## Keybindings

Workspace operations:

| Key | Action |
|-----|--------|
| LEADER + s | Fuzzy switch workspace |
| LEADER + S | Switch to previous workspace |
| LEADER + B | Jump to ~/System workspace |
| LEADER + a | Attach unix domain |
| LEADER + d | Detach unix domain |

Claude workspace operations (if claudectl available):

| Key | Action |
|-----|--------|
| LEADER + C | Create new Claude workspace |
| LEADER + c | Select and open Claude workspace |

## Features

### Workspace Switcher
- Fuzzy search across all workspaces
- Shows workspace path and status
- Customizable workspace formatter with nerd font icons

### Workspace Status
- Displays active workspace name in window title bar
- Updates when switching workspaces
- Color-coded with nerd font icon (󱂬)

### Claude Workspace Integration
- Create new Claude Code workspaces with custom names
- Fuzzy select and open existing workspaces
- Delete workspaces with confirmation

### Domain Management
- Quick attach/detach to unix domain
- Support for SSH, Docker, Kubernetes domains

## External Dependencies

- **smart_workspace_switcher**: Workspace switching plugin (auto-installed)
- **claudectl** (optional): Claude workspace management CLI
  - Get it from: https://github.com/anthropics/claude-code

## Installation

Smart workspace switcher is installed automatically by WezTerm.

For Claude workspace support (optional):

```bash
# Install Claude CLI which includes claudectl
curl https://claude.sh | sh

# Or install from source
git clone https://github.com/anthropics/claude-code
cd claude-code
cargo install --path .
```

## Related Modules

- `editing/keybindings` - Core pane/tab navigation
- `integration/plugins` - Smart workspace switcher plugin
- `workflows/git` - Git operations complement workspace management
