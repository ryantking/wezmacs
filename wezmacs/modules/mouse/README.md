# mouse module

Configures mouse bindings and behavior for text selection, link opening, and interaction.

## Features

- **Left-Click Selection**: Single click copies selected text to clipboard
- **Leader+Click**: Open link under cursor or extend selection
- **Quadruple-Click**: Select semantic zone (word, expression, or code block)
- **Wheel Scroll**: Customized scroll speed in alternate buffer
- **Leader Modifier Bypass**: CMD key bypasses mouse reporting from apps

## Configuration

```lua
flags = {
  behavior = {
    mouse = {
      leader_mod = "CMD"  -- Modifier for link opening
    }
  }
}
```

## Mouse Bindings

| Action | Trigger |
|--------|---------|
| Copy selection | Left-click up |
| Open link/extend | CMD + left-click up |
| Select semantic zone | Quadruple-click down |

## Selection Modes

- **Normal Selection**: Single/double/triple click for word/line/paragraph
- **Semantic Zone**: Quadruple-click to select logical code blocks
- **Link Opening**: CMD+click on URLs to open them

## External Dependencies

None. Uses only WezTerm builtin features.

## Related Modules

- `ui/tabbar` - Tab bar interaction also uses mouse events
- `editing/keybindings` - Keyboard navigation complements mouse control
