# window module

Configures WezTerm window behavior, padding, scrolling, and cursor appearance.

## Features

- **Window Decorations**: Resize-only decorations (no minimize/maximize buttons)
- **Padding**: Configurable uniform padding around terminal content
- **Scrollback**: Large 5000-line scrollback buffer (default)
- **Scroll Bar**: Visual indicator in window chrome
- **Cursor**: Blinking block cursor with smooth easing animations
- **No Audio Bell**: Disabled for quiet operation

## Configuration

```lua
flags = {
  ui = {
    window = {
      padding = 16,           -- Pixels of padding (all sides)
      scrollback_lines = 5000 -- Lines to keep in buffer
    }
  }
}
```

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
