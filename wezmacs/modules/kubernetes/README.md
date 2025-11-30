# kubernetes module

Kubernetes cluster management and monitoring through k9s terminal UI.

## Features

- **K9s Launcher**: Launch k9s in a new tab for cluster management
- **Quick Access**: Single keybinding to start cluster monitoring
- **Configurable Binding**: Customize the launch keybinding

## Configuration

Enable in `~/.config/wezmacs/modules.lua`:
```lua
return {
  "kubernetes"
}
```

Configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  kubernetes = {
    keybinding = "k",      -- Key to launch k9s
    modifier = "LEADER",   -- Modifier key
  }
}
```

## Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `LEADER+k` | Launch k9s | Open k9s in new tab for cluster management |

## External Dependencies

- **k9s**: Kubernetes CLI cluster manager
  - Install: `brew install k9s` (macOS)
  - Homepage: https://k9scli.io/

## Usage

Press `LEADER+k` (default: `CMD+Space` then `k`) to launch k9s in a new tab.

K9s provides a terminal UI for managing Kubernetes clusters with:
- Pod, deployment, and service management
- Resource monitoring and logs
- Quick navigation and filtering
- Cluster context switching
