# claude module

Provides Claude Code integration and workspace management.

## Configuration

Enable in `~/.config/wezmacs/modules.lua`:
```lua
return {
  "claude"
}
```

Configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  claude = {
    leader_key = "c",        -- Claude menu key
    leader_mod = "LEADER"    -- Modifier for Claude menu
  }
}
```

## Keybindings

Claude operations:

| Key | Action |
|-----|--------|
| LEADER + c | Activate Claude menu |
| Then c | Open new Claude session |
| Escape | Exit Claude menu |

## Features

- **Quick Launch**: Open new Claude Code session in terminal
- **Menu System**: Leader-based modal menu for Claude operations
- **Shell Integration**: Spawns Claude in fish shell by default

## External Dependencies

- **claude**: Claude CLI tool
  - Get it from: https://claude.sh
  - Includes: `claude` command and `claudectl` for workspace management

## Installation

```bash
# Install Claude CLI
curl https://claude.sh | sh

# Or manual installation
# Follow instructions at https://claude.sh
```

## Usage

### Basic Usage

Press `LEADER+c` to open Claude menu, then:
- Press `c` to open a new Claude Code session

### Integration with Workspace Module

When both `claude` and `workspace` modules are enabled:
- `LEADER+c` (from claude module) - Open Claude menu
- `LEADER+C` (from workspace module) - Create Claude workspace
- `LEADER+s` (from workspace module) - Select Claude workspace

This allows you to manage multiple Claude workspaces and quickly jump between them.

## Example Workflow

1. Enable both `claude` and `workspace` modules
2. Press `LEADER+c, c` to open Claude in current directory
3. Press `LEADER+C` to create a new Claude workspace with a name
4. Press `LEADER+s` to fuzzy search and open any Claude workspace
5. Press `LEADER+c, c` to open Claude in that workspace

## Related Modules

- `workflows/workspace` - Claude workspace management (create, list, delete)
- `editing/keybindings` - Core navigation and pane management
- `integration/plugins` - Plugin support for extended functionality

## Notes

- Claude module opens sessions in a new tab by default
- Workspace module provides the `LEADER+C`, `LEADER+c` (different from `LEADER+c, c` menu) keybindings
- Both modules can be used independently or together
