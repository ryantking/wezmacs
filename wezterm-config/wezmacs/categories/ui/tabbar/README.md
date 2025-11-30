# tabbar module

Provides custom tab bar with process icons, decorative separators, and smart title formatting.

## Features

- **Process Icons**: 25+ nerd font icons for common CLI tools (bash, fish, git, docker, etc.)
- **Smart Titles**: Auto-generates titles from working directory or application context
- **Zoom Indicator**: Shows 🔍 emoji when pane is zoomed
- **Decorative Separators**: Solid arrows between active/adjacent tabs, thin arrows elsewhere
- **Auto-hide**: Tab bar automatically hidden when only one tab open
- **Full Title Replacements**: Custom display names for applications (k9s → "🎮 Kubernetes")

## Configuration

```lua
flags = {
  ui = {
    tabbar = {}  -- No configurable flags currently
  }
}
```

## Supported Icons

Shells, editors, and development tools:
- **Shells**: bash, fish, zsh
- **Editors**: hx (Helix), nvim, vim
- **VCS**: git, lazygit
- **File Managers**: yazi
- **Build Tools**: cargo, make, just, go, lua
- **Languages**: python, python3, node, ruby
- **DevOps**: docker, kubectl, k9s, lazydocker
- **Package Managers**: brew, pip, uv
- **Other**: curl, wget, gh, psql, sudo

## Full Title Replacements

These applications get custom display names:

- `k9s` → "🎮 Kubernetes"
- `lazydocker` → "🐋 Docker"
- `spotify_player` → "🎵 Spotify"
- `btm` → "📊 Bottom"
- `htop` → "📈 Top"
- `btop` → "📈 Btop"

## Title Generation Logic

1. Check if application has a full title replacement - use that
2. Check if application has an icon:
   - If app has context/title: prepend icon
   - Otherwise: prepend icon + working directory name
3. If pane is zoomed: prepend 🔍 emoji
4. Trim very long titles (configurable via `tab_max_width`)

## External Dependencies

None. Uses WezTerm builtin nerd fonts.

## Keybindings

This module does not define any keybindings.
