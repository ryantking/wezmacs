# fonts module

Provides comprehensive font configuration for terminal and UI elements.

## Configuration

Enable in `~/.config/wezmacs/config.lua`:
```lua
return {
  fonts = {
    font = nil,         -- nil = use WezTerm default
    font_size = nil,
    font_rules = nil,   -- nil = auto-generate, {} = disable
    ui_font = nil,
    ui_font_size = nil,

    -- Feature flags:
    -- ligatures = {},
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `font` | string or nil | nil | Terminal font family name |
| `font_size` | number or nil | nil | Terminal font size in points |
| `font_rules` | table or nil | nil | Font rules for text styles (see below) |
| `ui_font` | string or nil | nil | UI elements font family |
| `ui_font_size` | number or nil | nil | UI elements font size |

### font_rules Behavior

- `nil` (default): Auto-generate rules if `font` is set
- `{}` (empty table): Disable font rules entirely
- `[...]` (custom array): Use custom font rules

## Usage

### Use WezTerm Defaults

```lua
fonts = {}
```

### Set Custom Terminal Font

```lua
fonts = {
  font = "Iosevka Mono",
  font_size = 16,
}
```

This automatically generates font rules for Bold, Italic, etc.

### Disable Font Rules

```lua
fonts = {
  font = "Iosevka Mono",
  font_size = 16,
  font_rules = {},  -- Explicitly disable
}
```

### Custom Font Rules

```lua
fonts = {
  font = "Iosevka Mono",
  font_rules = {
    {
      intensity = "Bold",
      font = wezterm.font({ family = "Iosevka Mono", weight = "Black" }),
    },
  },
}
```

### Configure UI Fonts

```lua
fonts = {
  font = "Iosevka Mono",
  font_size = 16,
  ui_font = "Iosevka",
  ui_font_size = 14,
}
```

UI fonts affect:
- Character selector (`char_select`)
- Command palette
- Window frame title

### Enable Ligatures

```lua
fonts = {
  font = "Fira Code",
  font_size = 14,
  ligatures = {},  -- Enable with default harfbuzz features
}
```

### Custom Ligature Features

```lua
fonts = {
  font = "Fira Code",
  ligatures = {
    harfbuzz_features = { "calt", "liga", "ss01", "ss02" },
  },
}
```

## Feature Flags

### ligatures

Enables font ligatures with configurable harfbuzz features.

**Config Schema**:
```lua
{
  harfbuzz_features = nil  -- nil = use default features
}
```

**Default harfbuzz features**:
- `ss01-ss08`: Stylistic sets
- `calt`: Contextual alternates
- `liga`: Standard ligatures
- `dlig`: Discretionary ligatures

## Popular Font Choices

- **Monospace with Ligatures**: Fira Code, Cascadia Code, JetBrains Mono
- **Classic Monospace**: Iosevka, Hack, Monaco, Menlo
- **Programming**: Source Code Pro, Inconsolata, DejaVu Sans Mono

## Related Modules

- `ui/theme` - Color scheme configuration
- `ui/window` - Window behavior (font colors depend on theme)
