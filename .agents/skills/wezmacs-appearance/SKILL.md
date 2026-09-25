---
name: wezmacs-appearance
description: Use when changing WezMacs theme, window frames, tabs, titles, unread indicators, glyphs or width handling.
compatibility: OpenCode and other agents supporting repository-local skills
---

# Appearance and tab contracts

Read docs/appearance.md, wezmacs/theme.lua, modules/window/init.lua,
modules/tabs/init.lua and hooks.lua. Load wezmacs-validation.

- The exact bundled scheme is `tokyonight-storm`, not similarly named Gogh/Night
  palettes. Resolve the installed palette; do not hand-copy hex colors. Retain
  native ANSI/cursor/selection/split colors. Cache lookup, return deep independent
  copies, and fill partial tab-state fields without erasing explicit values.
- Storm tabs use the dark strip background, blue active text, normal foreground
  hover and readable ANSI white inactive/new-tab text. Preserve other schemes'
  explicit styles and user setup overrides.
- Never pass resolved native ColorSpec variants through the recursive options
  merger. Set overrides after theme setup so Color versus AnsiColor is atomic.
  Exercise mismatched variants through strict native config conversion.
- Fancy titlebar background comes from window_frame, retro from colors.tab_bar.
  Align them without discarding explicit frame overrides. Correct native option
  names are show_new_tab_button_in_tab_bar and show_close_tab_button_in_tabs.
- Preserve manual titles verbatim and informative OSC/application titles. Rewrite
  only exact bare known executable titles. node/python are not agent identities.
  Foreground/CWD metadata is a lazy fallback, not subprocess/file I/O per callback.
- has_unseen_output means unread output, not agent completion/failure/approval.
  Inspect all panes in inactive tabs; let native focus clear it. Preserve index
  and zoom markers and avoid state mutation in format callbacks.
- Retro max_width is a cell budget; fancy width is pixel-layout territory. Use
  native column_width/truncate_right, not bytes. Cover tiny budgets, CJK, emoji
  and combining marks under the actual runtime.

Regressions: tests/theme_test.lua, window_test.lua, tabs_test.lua and
appearance_native.lua. Compare complete native show-keys output when preserving
navigation (normalize only generated callback identities). Native conversion is
not pixel inspection; use the validation skill's disposable GUI protocol when needed.
