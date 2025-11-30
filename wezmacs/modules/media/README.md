# media module

Spotify playback control through spotify_player terminal UI.

## Features

- **Spotify Player Launcher**: Launch spotify_player in a new tab
- **Terminal Playback**: Control Spotify from the terminal
- **Quick Access**: Single keybinding to start media player
- **Configurable Binding**: Customize the launch keybinding

## Configuration

Enable in `~/.config/wezmacs/modules.lua`:
```lua
return {
  "media"
}
```

Configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  media = {
    keybinding = "m",      -- Key to launch spotify_player
    modifier = "LEADER",   -- Modifier key
  }
}
```

## Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `LEADER+m` | Launch spotify_player | Open spotify_player in new tab |

## External Dependencies

- **spotify_player**: Terminal UI for Spotify
  - Install: `brew install spotify_player` (macOS)
  - Homepage: https://github.com/aome510/spotify-player
  - Requires: Spotify Premium account

## Usage

Press `LEADER+m` (default: `CMD+Space` then `m`) to launch spotify_player in a new tab.

Spotify_player provides a terminal UI for Spotify with:
- Playback control (play, pause, skip)
- Playlist and album browsing
- Search functionality
- Queue management
- Vi-like keybindings
- Device selection
