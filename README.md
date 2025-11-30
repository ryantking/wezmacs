# WezMacs

A modular, Doom Emacs-inspired configuration framework for WezTerm. Mix and match features to build your perfect terminal setup.

## Installation

### 1. Clone the Repository

Clone WezMacs to your WezTerm configuration directory:

```bash
git clone https://github.com/yourusername/wezmacs.git ~/.config/wezterm
```

### 2. Initialize Your Configuration

Set up the user configuration directory and default config:

```bash
cd ~/.config/wezterm
just install
```

This creates `~/.config/wezmacs/config.lua` with a starter configuration.

**Manual Setup** (if not using `just`):

```bash
mkdir -p ~/.config/wezmacs/custom-modules
cp user/config.lua ~/.config/wezmacs/config.lua
```

### 3. Customize Your Setup

Edit `~/.config/wezmacs/config.lua` to select which modules to enable:

```lua
return {
  modules = {
    ui = { "appearance", "tabbar", "window" },
    behavior = { "mouse" },
    editing = { "keybindings" },
    workflows = { "git", "workspace" },
    integration = { "plugins" },
  },
  flags = {
    ui = { theme = "Horizon Dark (Gogh)" },
  },
}
```

### 4. Reload WezTerm

WezTerm automatically reloads your configuration. You can manually reload with **Cmd+Option+R** on macOS (or your configured reload key).

### Updating WezMacs

To update the framework to the latest version:

```bash
cd ~/.config/wezterm
git pull origin main
just update
```

Your `~/.config/wezmacs/config.lua` configuration is preserved.

### Uninstalling WezMacs

To remove WezMacs and restore your original configuration:

```bash
cd ~/.config/wezterm
just uninstall
```

Your user configuration at `~/.config/wezmacs/` is preserved for reference.

## What's Inside

WezMacs provides a collection of carefully crafted modules organized by concern:

### 🎨 UI Modules
- **appearance**: Color schemes, fonts, visual styling
- **tabbar**: Custom tab bar with app icons
- **window**: Window padding, scrolling, cursor behavior

### ⚙️ Behavior Modules
- **mouse**: Selection, link opening, semantic zone selection

### ⌨️ Editing Modules
- **keybindings**: Pane/tab management, navigation, utilities (50+ bindings)

### 🔗 Integration Modules
- **plugins**: Smart workspace switcher, quick domains

### 🚀 Workflow Modules
- **git**: Lazygit integration with smart-split
- **workspace**: Workspace switching with fuzzy search
- **claude**: Claude Code integration

## Module Documentation

Each module includes its own README with:
- Features and configuration options
- Keybindings and usage examples
- External dependencies
- Installation instructions

See `wezmacs/modules/*/README.md` for details.

## Configuration

### Basic Usage

```lua
-- ~/.config/wezmacs/config.lua
return {
  modules = {
    ui = { "appearance", "tabbar" },
    behavior = { "mouse" },
    editing = { "keybindings" },
    workflows = { "git", "workspace", "claude" },
    integration = { "plugins" },
  },
}
```

### With Flags

Customize module behavior without editing module code:

```lua
return {
  modules = {
    ui = { "appearance", "tabbar", "window" },
    workflows = { "git", "workspace" },
  },

  flags = {
    ui = {
      theme = "Nord",
      font = "JetBrains Mono",
      font_size = 18,
    },
    workflows = {
      git = {
        leader_key = "g",
        leader_mod = "LEADER",
      },
    },
  },
}
```

### With Overrides

Apply final tweaks after all modules load:

```lua
return {
  modules = {
    ui = { "appearance", "tabbar" },
    editing = { "keybindings" },
  },

  overrides = function(config)
    -- Custom keybindings
    config.keys = config.keys or {}
    table.insert(config.keys, {
      key = "q",
      mods = "CMD",
      action = wezterm.action.QuitApplication,
    })
  end,
}
```

## Architecture

WezMacs follows a pragmatic hybrid approach inspired by Doom Emacs and LazyVim:

- **Module System**: Each module is a Lua file with metadata and two phases (init, apply)
- **Flat Structure**: No categories in code - just `wezmacs/modules/modulename/`
- **Plain Lua Config**: No DSL or macros - just standard Lua tables
- **Two-Phase Loading**: Init phase for validation, apply phase for configuration
- **Feature Flags**: Per-module configuration without editing module code
- **Custom Modules**: Users can add modules to `user/custom-modules/`

See [FRAMEWORK.md](FRAMEWORK.md) for architectural details.

## Creating Custom Modules

Create a new module in `~/.config/wezterm/user/custom-modules/`:

```lua
-- user/custom-modules/my-module/init.lua
local M = {}

M._NAME = "my-module"
M._CATEGORY = "custom"
M._VERSION = "0.1.0"
M._DESCRIPTION = "My custom module"
M._EXTERNAL_DEPS = {}
M._FLAGS_SCHEMA = {}

function M.init(flags, log)
  return {}  -- Module state
end

function M.apply_to_config(config, flags, state)
  -- Apply your configuration here
  config.keys = config.keys or {}
  -- ... add keybindings, event handlers, etc
end

return M
```

Enable it in `user/config.lua`:

```lua
return {
  modules = {
    custom = { "my-module" },
  },
}
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Key Bindings

Core navigation (available with all configurations):

| Binding | Action |
|---------|--------|
| LEADER (CMD+Space) | Activate leader mode (5 sec timeout) |
| LEADER+- | Split pane horizontally |
| LEADER+\| | Split pane vertically |
| LEADER+t | New tab |
| LEADER+w | Close tab |
| LEADER+z | Zoom pane |
| LEADER+p | Select pane |
| CTRL+Arrow | Navigate between panes |

Additional keybindings depend on which workflow modules you enable:
- Git operations: LEADER+g (git module)
- Workspace switching: LEADER+s (workspace module)
- Claude integration: LEADER+c (claude module)

See module READMEs for complete keybinding documentation.

## External Dependencies

Required tools depend on which modules you enable:

- **git module**: lazygit, git, delta
- **workspace module**: smart_workspace_switcher (plugin, auto-installed)
- **claude module**: claude CLI, claudectl (optional)
- **plugins module**: smart_workspace_switcher, quick_domains (both plugins, auto-installed)

Install recommended tools:

```bash
# macOS (Homebrew)
brew install lazygit delta wezterm

# Or from source
# See individual module READMEs for detailed installation
```

## Troubleshooting

### Module not loading
Check that the module name matches exactly: `wezmacs/modules/modulename/init.lua`

### Keybindings not working
Make sure the required workflow module is enabled (e.g., enable `git` module for LEADER+g)

### Colors not applied
Verify the theme name exists in WezTerm's builtin color schemes

### Plugin not installing
WezTerm plugins install automatically on first use. Check your internet connection.

## Examples

See `examples/` directory for complete configuration examples:
- `minimal.lua` - Bare essentials (3 modules)
- `full.lua` - All modules enabled
- `advanced.lua` - Custom modules + overrides

## Related Projects

- [Doom Emacs](https://github.com/doomemacs/doomemacs) - Inspiration for modular configuration
- [LazyVim](https://github.com/LazyVim/LazyVim) - Vim inspiration for simplicity
- [WezTerm](https://wezfurlong.org/wezterm/) - The terminal we're configuring
- [smart_workspace_switcher](https://github.com/MLFlexer/smart_workspace_switcher.wezterm) - Fuzzy workspace switching
- [quick_domains](https://github.com/DavidRR-F/quick_domains.wezterm) - SSH/Docker/K8s domains

## License

[Your License] - See LICENSE file

## Contributing

Contributions welcome! Please:

1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Create a new module following the template
3. Include comprehensive README documentation
4. Submit a pull request

## Support

- Check module READMEs for feature-specific questions
- See [FRAMEWORK.md](FRAMEWORK.md) for architecture questions
- See [CONTRIBUTING.md](CONTRIBUTING.md) for development questions
