# Appearance and tab context

`window` applies the theme, UI fonts, frame and spacing; `tabs` owns tab visibility,
navigation and labels. `term` still owns terminal fonts, scrolling, cursor/input
protocols and graphics. No additional multiplexer, status daemon or agent hook is
involved.

## Tokyo Night Storm

The framework default is WezTerm's bundled **`tokyonight-storm`**. To select it
explicitly in your global `config.lua`:

```lua
return { color_scheme = "tokyonight-storm" }
```

This is distinct from `Tokyo Night` and the Gogh variants. We retain the native
ANSI, cursor, selection and split colors instead of reproducing the palette.
The theme helper fills missing UI colors and returns independent palette copies.
Storm's tabs share the dark strip background: active text uses palette blue,
hover text uses the normal foreground, and inactive/new-tab text uses ANSI white
rather than the low-contrast comment color. This applies to both fancy and retro
bars; other schemes retain their explicit native tab styling. Copy-mode and
quick-select highlights also derive from the selected palette. Other built-in
schemes remain selectable; `Rose Pine` retains its opt-in plugin dependency.

The fancy tab-bar frame uses the same background as the retro strip. Windows and
text are opaque; inactive panes retain their saturation at 90% brightness so a
side-by-side editor and agent remain readable. Changing font size keeps the
window dimensions fixed. Decorations, close behavior, padding and configured
fonts are otherwise preserved.

Native window/tab settings remain module options. For example, in `modules.lua`:

```lua
return {
  "term",
  { "window", opts = {
    padding = 16,
    inactive_pane_hsb = { saturation = 1, brightness = 0.9 },
    adjust_window_size_when_changing_font_size = false,
  }, setup = function(config)
    -- Optional native overrides run after theme application. Assign ColorSpec
    -- variants whole; never recursively merge Color and AnsiColor together.
    config.colors.quick_select_match_bg = { AnsiColor = "Green" }
    config.colors.tab_bar.active_tab.intensity = "Bold"
  end },
  { "tabs", opts = {
    use_fancy_tab_bar = true,
    hide_tab_bar_if_only_one_tab = false,
    tab_max_width = 32, -- native cell limit for the retro tab bar
  } },
}
```

The single-tab bar stays visible so pane/application context and existing workspace
status do not disappear. Choose `hide_tab_bar_if_only_one_tab = true` to restore
the old behavior. The fancy bar performs its own pixel-based layout; the retro
renderer uses native cell-width truncation rather than byte slicing.

## Titles and attention

- An explicit tab title wins, without application-name rewriting.
- Informative application/OSC titles are preserved: Neovim buffer names and agent
  task/session titles are useful content, not something to replace with a logo.
- Bare known application names get readable labels and directory context when
  available. Foreground executable and working-directory information provide
  fallbacks when titles are missing. `node` and `python` are not assumed to be
  agents.
- Labels include the tab number and a `[Z]` marker for zoomed panes.
- A dot on an inactive tab means **unseen terminal output in any of its panes**.
  It does **not** mean an agent completed, failed, or needs approval. Visiting the
  pane lets native WezTerm clear its unseen-output state.

The callback does not run subprocesses, read files, query agent APIs or change
pane state. It uses the title/metadata supplied by WezTerm and preserves remote
OSC titles when local process information is unavailable.

To assign a deliberate tab title, use native `wezterm cli set-tab-title` or
`tab:set_title()` in your own integration. Clearing the explicit title restores
automatic labels. Existing navigation shortcuts are unchanged.

Neovim can emit its buffer title with `vim.opt.title = true`; this is an optional
editor-side setting, not installed by this configuration. An application must
emit a meaningful title for session/task details to appear. WezMacs does not
invent agent progress or install shell/editor hooks.

## Verification boundary

`just check` covers formatting, LuaLS, regressions and strict native configuration
validation. Embedded-runtime appearance tests also cover dark Storm tab states
and atomic ColorSpec replacements through the real module loader. Unit cases
cover title precedence, missing metadata, path handling, zoom/output markers and
title-width behavior. These checks do not prove GUI rendering or
agent session integration. Visual acceptance should use a disposable window,
clean Neovim and clearly labelled synthetic OSC-title/output fixtures, never type
into an existing session or launch a billable agent simply to test appearance.

References: [appearance](https://wezterm.org/config/appearance.html),
[format-tab-title](https://wezterm.org/config/lua/window-events/format-tab-title.html),
[PaneInformation](https://wezterm.org/config/lua/PaneInformation.html),
[window_frame](https://wezterm.org/config/lua/config/window_frame.html).
