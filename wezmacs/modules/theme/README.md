# theme module

Provides color scheme selection and tab bar color customization.

## Configuration

Enable in `~/.config/wezmacs/config.lua`:
```lua
return {
  theme = {
    color_scheme = nil,  -- nil = use WezTerm default
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `color_scheme` | string or nil | nil | WezTerm built-in color scheme name |

## Usage

### Use WezTerm Default Theme

```lua
theme = {
  color_scheme = nil,
}
```

### Select a Custom Theme

```lua
theme = {
  color_scheme = "Horizon Dark (Gogh)",
}
```

### Popular Themes

- `"Tokyo Night"`
- `"Catppuccin Mocha"`
- `"Dracula"`
- `"Nord"`
- `"Gruvbox Dark"`
- `"Solarized Dark"`

Use `wezterm.get_builtin_color_schemes()` to see all available themes.

## Features

- **Automatic Tab Bar Colors**: When a theme is selected, tab bar colors are automatically customized to match
- **Error Handling**: Invalid theme names log an error and fall back to WezTerm default
- **Optional**: If not enabled or color_scheme is nil, WezTerm uses its default theme

## Integration with Other Modules

- **tabbar**: Reads colors from resolved palette (automatically uses theme colors)
- **window**: Applies theme-based colors to window frame, char select, and command palette

## Related Modules

- `ui/fonts` - Font configuration
- `ui/tabbar` - Tab bar formatting
- `ui/window` - Window behavior and styling
