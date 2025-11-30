# git module

Provides git workflow integration with lazygit and git diff utilities.

## Configuration

```lua
flags = {
  workflows = {
    git = {
      leader_key = "g",        -- Git submenu key
      leader_mod = "LEADER"    -- Modifier for git submenu
    }
  }
}
```

## Keybindings

Activate with `LEADER + g` then:

| Key | Action |
|-----|--------|
| g | Lazygit in smart split (auto-orient) |
| G | Lazygit in new tab |
| d | Git diff main in smart split |
| D | Git diff main in new window |
| Escape | Exit git menu |

## Features

### Smart Split

Lazygit and git diff automatically orient based on window dimensions:
- **Portrait** (taller than wide): Split horizontally
- **Landscape** (wider than tall): Split vertically
- **Size**: 50% of current pane

### Lazy Git

TUI for git with full repository management:
- View branches, commits, stashes
- Create/switch/delete branches
- Commit, amend, rebase interactively

### Git Diff

Shows differences from main branch:
- Falls back to master if main doesn't exist
- Falls back to origin/main or origin/master if local branches unavailable
- Falls back to git status if no branches available
- Formatted with delta for better readability

## External Dependencies

- **lazygit**: Git TUI (https://github.com/jesseduffield/lazygit)
- **git**: Version control
- **delta**: Diff formatter (optional, git diff works without it)

## Installation

```bash
# macOS (Homebrew)
brew install lazygit

# Or from source
git clone https://github.com/jesseduffield/lazygit.git
cd lazygit
go install
```

## Related Modules

- `integration/plugins` - Workspace switcher pairs well with git workflows
- `editing/keybindings` - Core navigation bindings complement git operations
