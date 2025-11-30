# keybindings module

Core keyboard bindings for pane and tab management, selection modes, and utilities.

## Configuration

Enable in `~/.config/wezmacs/modules.lua`:
```lua
return {
  "keybindings"
}
```

Configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  keybindings = {
    leader_key = "Space",   -- Leader key
    leader_mod = "CMD"      -- Leader modifier
  }
}
```

## Leader Key

- **Binding**: CMD+Space
- **Timeout**: 5 seconds
- **Usage**: All LEADER+ bindings require pressing this first

## Pane Management

| Binding | Action |
|---------|--------|
| LEADER+- | Split horizontal (30% below) |
| LEADER+\| | Split vertical (25% right) |
| LEADER+z | Toggle pane zoom |
| LEADER+p | Pane select |
| LEADER+P | Pane swap |
| LEADER+n | Move pane to new tab |
| LEADER+N | Move pane to new window |

## Pane Navigation

| Binding | Action |
|---------|--------|
| CTRL+Arrow | Navigate between panes |

## Pane Resizing

- **Activation**: LEADER+SHIFT+Arrow (sticky mode)
- **Resize**: Arrow keys while in mode
- **Exit**: Escape or Enter

## Tab Management

| Binding | Action |
|---------|--------|
| LEADER+t | New tab |
| LEADER+w | Close tab |

## Application Launchers

| Binding | Action | App |
|---------|--------|-----|
| LEADER+y | New tab | Yazi (file manager) |
| LEADER+Y | New tab as root | Yazi at / |
| LEADER+h | New tab | Bottom (system monitor) |
| LEADER+k | New tab | K9s (Kubernetes) |
| LEADER+D | New tab | LazyDocker |
| LEADER+E | New tab | Helix at current dir |
| LEADER+C | Background | Cursor IDE at current dir |
| LEADER+m | New tab | Spotify player |

## Selection & Utilities

| Binding | Action |
|---------|--------|
| LEADER+q | Quick select (URL, path, hash, IP, UUID) |
| LEADER+e | Character selector |
| SHIFT+Up | Scroll to previous prompt |
| SHIFT+Down | Scroll to next prompt |
| LEADER+Enter | Toggle fullscreen |
| LEADER+L | Show debug overlay |
| SHIFT+Enter | Send newline (Claude Code) |

## Quick Select Patterns

The LEADER+q binding searches for:
- HTTP/HTTPS URLs
- Git SSH URLs
- File URLs
- Local file paths
- Absolute paths
- Git commit hashes
- IP addresses
- UUIDs

## External Dependencies

None. Uses only WezTerm builtin features.

## Related Modules

- `workflows/git` - Git operation keybindings
- `workflows/workspace` - Workspace switching
- `workflows/claude` - Claude integration
- `behavior/mouse` - Mouse-based selection
