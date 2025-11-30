# system-monitor module

System resource monitoring through bottom terminal UI.

## Features

- **Bottom Launcher**: Launch bottom system monitor in a new tab
- **Resource Monitoring**: CPU, memory, disk, network, and process monitoring
- **Quick Access**: Single keybinding to view system resources
- **Configurable Binding**: Customize the launch keybinding

## Configuration

Enable in `~/.config/wezmacs/modules.lua`:
```lua
return {
  "system-monitor"
}
```

Configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  system_monitor = {
    keybinding = "h",      -- Key to launch bottom
    modifier = "LEADER",   -- Modifier key
  }
}
```

## Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `LEADER+h` | Launch bottom | Open bottom system monitor in new tab |

## External Dependencies

- **bottom (btm)**: Terminal system monitor
  - Install: `brew install bottom` (macOS)
  - Homepage: https://github.com/ClementTsang/bottom

## Usage

Press `LEADER+h` (default: `CMD+Space` then `h`) to launch bottom in a new tab.

Bottom provides a terminal UI for system monitoring with:
- CPU usage per core
- Memory and swap usage
- Disk I/O and usage
- Network bandwidth
- Process list with filtering
- Temperature sensors
- Battery information
