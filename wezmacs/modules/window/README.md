# window module

Configures WezTerm window behavior, padding, scrolling, cursor appearance, and UI widget styling.

## Features

- **Window Decorations**: Configurable window chrome (default: RESIZE)
- **Padding**: Configurable uniform padding around terminal content
- **Scrollback**: Large 5000-line scrollback buffer (default)
- **Scroll Bar**: Visual indicator in window chrome
- **Cursor**: Blinking block cursor with smooth easing animations
- **No Audio Bell**: Disabled for quiet operation
- **Theme Integration**: Applies theme colors to window frame, char select, and command palette

## Configuration

Enable in `~/.config/wezmacs/config.lua`:
```lua
return {
  window = {
    decorations = "RESIZE",  -- Window chrome style
    padding = 16,            -- Pixels of padding (all sides)
    scrollback_lines = 5000, -- Lines to keep in buffer
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `decorations` | string | "RESIZE" | Window decoration style |
| `padding` | number | 16 | Pixels of padding on all sides |
| `scrollback_lines` | number | 5000 | Lines to keep in scrollback buffer |

### Window Decoration Options

- `"RESIZE"` - Only resize handle (minimal chrome)
- `"TITLE"` - Title bar + resize handle
- `"TITLE | RESIZE"` - Both title and resize
- `"NONE"` - No window decorations

## Cursor Settings

- **Style**: Blinking block (█)
- **Blink Rate**: 500ms per blink cycle
- **Ease-in**: EaseIn animation
- **Ease-out**: EaseOut animation

## Scrollback

- **Default Size**: 5000 lines
- **Indicator**: Visual scroll bar enabled
- **Access**: Scroll with mouse wheel or trackpad

## Window Behavior

- **Close Confirmation**: Never prompt (instant close)
- **Decorations**: Resize handle only (minimal chrome)

## External Dependencies

None. Uses only WezTerm builtin features.

## Keybindings

This module does not define any keybindings. See related modules:
- `behavior/scrolling` for scroll-related keybindings
- `editing/keybindings` for general navigation
