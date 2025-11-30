# editors module

Quick access to external code editors from WezTerm.

## Features

- **Helix Launcher**: Launch Helix terminal editor in current directory
- **Cursor Launcher**: Launch Cursor GUI editor in current directory
- **Context Aware**: Editors open in the current working directory
- **Configurable Bindings**: Customize launch keybindings

## Configuration

```lua
config = {
  development = {
    editors = {
      helix_keybinding = "E",     -- Key to launch Helix
      cursor_keybinding = "C",    -- Key to launch Cursor
      modifier = "LEADER",        -- Modifier key
    }
  }
}
```

## Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `LEADER+E` | Launch Helix | Open Helix editor in new tab at current directory |
| `LEADER+C` | Launch Cursor | Open Cursor editor GUI in current directory |

## External Dependencies

- **Helix (hx)**: Modern terminal text editor
  - Install: `brew install helix` (macOS)
  - Homepage: https://helix-editor.com/
  - Required

- **Cursor**: AI-powered code editor
  - Install: Download from https://cursor.sh/
  - Optional (Cursor keybinding will only work if installed)

## Usage

**Helix**: Press `LEADER+E` (default: `CMD+Space` then `Shift+e`) to launch Helix in a new tab.
Helix opens in the current working directory and provides:
- Vi-like modal editing
- Built-in LSP support
- Multiple selections
- Tree-sitter syntax highlighting

**Cursor**: Press `LEADER+C` (default: `CMD+Space` then `Shift+c`) to launch Cursor GUI.
Cursor opens in a new window with the current directory and provides:
- AI code completion
- VSCode-compatible extensions
- Integrated chat interface
- Full IDE features
