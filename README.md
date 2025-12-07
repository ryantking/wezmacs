# WezMacs

A modular, Doom Emacs-inspired configuration framework for WezTerm. Mix and match features to build your perfect terminal setup.

## Installation

### 1. Clone the Repository

Clone WezMacs to your WezTerm configuration directory:

```bash
git clone https://github.com/yourusername/wezmacs.git ~/.config/wezterm
```

### 2. Initialize Your Configuration

Set up the user configuration directory and default config files:

```bash
cd ~/.config/wezterm
just install
```

This creates two configuration files:
- `~/.config/wezmacs/modules.lua` - Module selection and feature flags
- `~/.config/wezmacs/config.lua` - Per-module configuration values

**Manual Setup** (if not using `just`):

```bash
mkdir -p ~/.config/wezmacs/custom-modules
cp user/modules.lua ~/.config/wezmacs/modules.lua
cp user/config.lua ~/.config/wezmacs/config.lua
```

### 3. Customize Your Setup

Edit `~/.config/wezmacs/modules.lua` to select which modules to enable:

```lua
return {
  "term",  -- Core terminal settings
  "tabs",
  "window",
  "mouse",
  "app",  -- Application keybindings
  "mux",  -- Workspace and pane management
  "git",
  "agent",
  "edit",  -- Editor and file manager
}
```

Edit `~/.config/wezmacs/config.lua` to configure module behavior:

```lua
return {
  term = {
    color_scheme = "Horizon Dark (Gogh)",
    font = "JetBrains Mono",
    font_size = 16,
  },
  git = {
    diff_branches = { "main", "master" },
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

Your `~/.config/wezmacs/modules.lua` and `~/.config/wezmacs/config.lua` configurations are preserved.

### Uninstalling WezMacs

To remove WezMacs and restore your original configuration:

```bash
cd ~/.config/wezterm
just uninstall
```

Your user configuration at `~/.config/wezmacs/` is preserved for reference.

## What's Inside

WezMacs provides a collection of carefully crafted modules organized by concern:

### 🎨 Core Modules
- **term**: Core terminal settings, fonts, colors, scrollback, clipboard, search
- **tabs**: Custom tab bar with app icons and tab management
- **window**: Window management and behavior
- **mouse**: Mouse bindings and selection behavior

### ⌨️ Keybinding Modules
- **app**: Application-level keybindings (quit, reload, commands)

### 🔗 Integration Modules
- **mux**: Domain management, workspace switching, and pane management
- **git**: Lazygit integration with smart-split
- **agent**: AI coding agent integration
- **app**: Application launchers (docker, kubernetes, media, system monitor)
- **edit**: Editor and file manager integration

## Module Documentation

Each module includes its own README with:
- Features and configuration options
- Keybindings and usage examples
- External dependencies
- Installation instructions

See `wezmacs/modules/*/README.md` for details.

## Configuration

WezMacs uses two configuration files to separate concerns:

### modules.lua - Module Selection

Choose which modules to load and enable optional feature flags:

```lua
-- ~/.config/wezmacs/modules.lua
return {
  -- Simple string: load with defaults
  "term",
  "tabs",
  "window",
  "mouse",
  "app",
  "keys",

  -- Table with opts: override module options
  { name = "git", opts = { diff_branches = { "main", "develop" } } },

  "agent",
  "mux",
  "edit",
}
```

### config.lua - Module Configuration

Configure how each module behaves:

```lua
-- ~/.config/wezmacs/config.lua
return {
  term = {
    color_scheme = "Horizon Dark (Gogh)",
    font = "JetBrains Mono",
    font_size = 16,
  },

  app = {
    leader_key = "Space",
    leader_mod = "CMD",
  },

  git = {
    diff_branches = { "main", "master" },
  },
}
```

### Configuration Pattern

1. **modules.lua** - WHAT to load (module names + feature flags)
2. **config.lua** - HOW to configure (settings for each module)

This separation keeps configuration clean and maintainable.

## Architecture

WezMacs follows a pragmatic hybrid approach inspired by Doom Emacs and LazyVim:

- **Module System**: Each module exports `name`, `description`, `deps`, `opts`, `keys`, and `setup` functions
- **Flat Structure**: No categories in code - just `wezmacs/modules/modulename/`
- **Dual Configuration**: Separate files for module selection (modules.lua) and configuration (config.lua)
- **Options Pattern**: Modules define `opts` (table or function) with defaults, merged with user config
- **Keybinding Format**: Mixed list/map format where list items are direct bindings and string keys create nested key tables
- **Global API**: Modules access `wezmacs.config` for global settings and `wezmacs.action` for custom actions
- **Custom Modules**: Users can add modules to `~/.config/wezmacs/custom-modules/`

See [FRAMEWORK.md](FRAMEWORK.md) for architectural details.

## Creating Custom Modules

Create a new module in `~/.config/wezmacs/custom-modules/`:

```lua
-- ~/.config/wezmacs/custom-modules/my-module/init.lua
local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
  name = "my-module",
  description = "My custom module",
  deps = { "tool1", "tool2" },

  opts = {
    some_option = "default_value",
    another_option = 42,
  },

  keys = function(opts)
    return {
      { key = "m", mods = "LEADER", action = act.SomeAction(), desc = "my-action" },
    }
  end,

  setup = function(config, opts)
    -- Modify config based on opts
    config.some_setting = opts.some_option
  end,
}
```

Enable it in `~/.config/wezmacs/modules.lua`:

```lua
return {
  "term",
  { name = "my-module", opts = { some_option = "custom" } },
}
```

Configure it in `~/.config/wezmacs/config.lua`:

```lua
return {
  ["my-module"] = {
    some_option = "custom_value",
  },
}
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Key Bindings

Core navigation (available with all configurations):

| Binding | Action |
|---------|--------|
| LEADER (Space/Ctrl) | Activate leader mode |
| LEADER+- | Split pane horizontally |
| LEADER+\| | Split pane vertically |
| LEADER+t | New tab |
| LEADER+w | Close tab |
| LEADER+z | Zoom pane |
| CTRL+Arrow | Navigate between panes |

Additional keybindings depend on which modules you enable:
- Git operations: LEADER+g (git module)
- Workspace switching: LEADER+s (mux module)
- Agent integration: LEADER+a (agent module)
- Application launchers: LEADER+, (app module)

See module READMEs for complete keybinding documentation.

## External Dependencies

Required tools depend on which modules you enable:

- **git module**: lazygit, git, delta, broot
- **mux module**: quick_domains and smart_workspace_switcher (plugins, auto-installed)
- **agent module**: agent CLI, agentctl (optional)
- **app module**: lazydocker, k9s, spotify_player, btm
- **edit module**: br (broot), yazi, editor/IDE

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
