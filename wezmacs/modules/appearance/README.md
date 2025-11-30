# appearance module

Provides color scheme, font configuration, and visual styling for WezTerm.

## Features

- **Color Schemes**: Support for all WezTerm builtin color schemes (default: Horizon Dark Gogh)
- **Font Configuration**: Iosevka Mono with extensive stylistic sets and ligatures
- **Font Rules**: Separate font weights for normal, bold, and half intensity text with italic support
- **UI Elements**: Consistent styling for tab bar, window frame, character selector, and command palette
- **Tab Bar Colors**: Customized active/inactive tab appearance

## Configuration

```lua
flags = {
  ui = {
    appearance = {
      theme = "Horizon Dark (Gogh)",  -- WezTerm builtin color scheme
      font = "Iosevka Mono",           -- Font family
      font_size = 16,                  -- Font size in points
    }
  }
}
```

## Available Color Schemes

This module uses WezTerm's builtin color schemes. Some popular options:

- `Horizon Dark (Gogh)` (default)
- `Nord`
- `Dracula`
- `One Dark (Gogh)`
- `Solarized Dark (Gogh)`
- `GitHub Dark`

Run `wezterm ls-fonts` to see available fonts on your system.

## Font Features

The appearance module enables the following Harfbuzz features:

- **Stylistic Sets**: ss01-ss08 for distinctive visual style
- **Ligatures**: Standard and discretionary ligatures
- **Contextual Alternates**: Proper contextual glyph selection

## Font Rules

Automatically applies different font weights based on text intensity:

- **Normal**: Medium weight
- **Bold**: ExtraBold weight
- **Half**: Thin weight
- **Italic variants**: Automatic italic style switching

## External Dependencies

None. Uses only WezTerm builtin features and fonts.

## Keybindings

This module does not define any keybindings.
