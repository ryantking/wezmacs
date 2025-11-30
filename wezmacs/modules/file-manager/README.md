# file-manager module

File management and browsing through yazi terminal file manager.

## Features

- **Yazi Launcher**: Launch yazi file manager in a new tab
- **Sudo Mode**: Open yazi with sudo privileges for system files
- **Quick Access**: Single keybindings for file management
- **Configurable Bindings**: Customize launch keybindings

## Configuration

Enable in `~/.config/wezmacs/modules.lua`:
```lua
return {
  "file-manager"
}
```

Configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  file_manager = {
    keybinding = "y",           -- Key to launch yazi
    sudo_keybinding = "Y",      -- Key to launch yazi with sudo
    modifier = "LEADER",        -- Modifier key
  }
}
```

## Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `LEADER+y` | Launch yazi | Open yazi file manager in current directory |
| `LEADER+Y` | Launch yazi (sudo) | Open yazi as root starting from / |

## External Dependencies

- **yazi**: Modern terminal file manager
  - Install: `brew install yazi` (macOS)
  - Homepage: https://yazi-rs.github.io/

## Usage

Press `LEADER+y` (default: `CMD+Space` then `y`) to launch yazi in the current directory.
Press `LEADER+Y` (default: `CMD+Space` then `Shift+y`) to launch yazi with sudo privileges from root directory.

Yazi provides a terminal UI for file management with:
- Vi-like keybindings
- File preview support
- Image preview in terminal
- Batch operations
- Fuzzy search and filtering
