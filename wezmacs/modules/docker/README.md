# docker module

Docker container and image management through lazydocker terminal UI.

## Features

- **Lazydocker Launcher**: Launch lazydocker in a new tab for container management
- **Quick Access**: Single keybinding to start Docker monitoring
- **Configurable Binding**: Customize the launch keybinding

## Configuration

```lua
config = {
  devops = {
    docker = {
      keybinding = "D",      -- Key to launch lazydocker (uppercase D)
      modifier = "LEADER",   -- Modifier key
    }
  }
}
```

## Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `LEADER+D` | Launch lazydocker | Open lazydocker in new tab for container management |

## External Dependencies

- **lazydocker**: Terminal UI for Docker management
  - Install: `brew install lazydocker` (macOS)
  - Homepage: https://github.com/jesseduffield/lazydocker

## Usage

Press `LEADER+D` (default: `CMD+Space` then `Shift+d`) to launch lazydocker in a new tab.

Lazydocker provides a terminal UI for managing Docker with:
- Container monitoring and logs
- Image and volume management
- Docker compose support
- Resource usage visualization
- Quick container actions (restart, stop, remove)
