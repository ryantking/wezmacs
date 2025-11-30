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
  "appearance",  -- Load with defaults
  "tabbar",
  "window",
  "mouse",
  "keybindings",
  { name = "git", flags = {} },  -- Load with optional flags
  "workspace",
  "domains",
}
```

Edit `~/.config/wezmacs/config.lua` to configure module behavior:

```lua
return {
  appearance = {
    theme = "Horizon Dark (Gogh)",
    font = "JetBrains Mono",
    font_size = 16,
  },
  git = {
    leader_key = "g",
    leader_mod = "LEADER",
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
- **kubernetes**: Kubernetes management (k9s)
- **docker**: Docker management (lazydocker)
- **file-manager**: File manager integration (yazi)
- **media**: Media player integration (spotify_player)
- **editors**: Editor launchers (helix, cursor)
- **system-monitor**: System monitoring (btm)

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
  "appearance",
  "tabbar",
  "window",
  "mouse",
  "keybindings",

  -- Table with flags: enable optional features
  { name = "git", flags = { "smartsplit" } },
  { name = "workspace", flags = {} },

  "claude",
  "domains",
}
```

### config.lua - Module Configuration

Configure how each module behaves:

```lua
-- ~/.config/wezmacs/config.lua
return {
  appearance = {
    theme = "Horizon Dark (Gogh)",
    font = "JetBrains Mono",
    font_size = 16,
  },

  keybindings = {
    leader_key = "Space",
    leader_mod = "CMD",
  },

  git = {
    leader_key = "g",
    leader_mod = "LEADER",
  },

  workspace = {
    leader_key = "s",
    leader_mod = "LEADER",
  },
}
```

### Configuration Pattern

1. **modules.lua** - WHAT to load (module names + feature flags)
2. **config.lua** - HOW to configure (settings for each module)

This separation keeps configuration clean and maintainable.

## Architecture

WezMacs follows a pragmatic hybrid approach inspired by Doom Emacs and LazyVim:

- **Module System**: Each module exports metadata and a single `apply_to_config` function
- **Flat Structure**: No categories in code - just `wezmacs/modules/modulename/`
- **Dual Configuration**: Separate files for module selection (modules.lua) and configuration (config.lua)
- **Framework-Managed Config**: The framework handles config merging and provides it via global API
- **Feature Flags**: Optional per-module flags, either simple flags or complex objects with config_schema and deps
- **Schema-Driven**: Modules declare _CONFIG_SCHEMA and _FEATURES for validation
- **Global API**: Modules use `wezmacs.get_config()` and `wezmacs.get_enabled_flags()` to access configuration
- **Custom Modules**: Users can add modules to `~/.config/wezmacs/custom-modules/`

See [FRAMEWORK.md](FRAMEWORK.md) for architectural details.

## Creating Custom Modules

Create a new module in `~/.config/wezmacs/custom-modules/`:

```lua
-- ~/.config/wezmacs/custom-modules/my-module/init.lua
local wezterm = require("wezterm")
local M = {}

M._NAME = "my-module"
M._CATEGORY = "custom"
M._VERSION = "0.1.0"
M._DESCRIPTION = "My custom module"
M._EXTERNAL_DEPS = {}

-- Feature flags (optional)
M._FEATURE_FLAGS = {}

-- Configuration schema with defaults
M._CONFIG_SCHEMA = {
  some_option = "default_value",
}

-- Init phase: merge user config with defaults
function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

-- Apply phase: modify WezTerm config
function M.apply_to_config(config, state)
  config.keys = config.keys or {}
  -- Use state.config.some_option for configuration
  -- Check state.flags for enabled feature flags
end

return M
```

Enable it in `~/.config/wezmacs/modules.lua`:

```lua
return {
  "appearance",
  { name = "my-module", flags = {} },
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
