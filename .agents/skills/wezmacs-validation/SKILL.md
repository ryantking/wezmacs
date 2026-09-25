---
name: wezmacs-validation
description: Use when testing any WezMacs change, native Lua APIs, smoke harnesses, toolchain failures or GUI acceptance.
compatibility: OpenCode and other agents supporting repository-local skills
---

# Validation and native-runtime evidence

Read CONTRIBUTING.md, Justfile, .luarc.json, .stylua.toml and the actual test
scripts first. Run `just check` from the repo root. It does not rewrite source.
`just fmt` writes; `just demo` opens a GUI; `just types` fetches pinned annotations.
Never substitute either of the latter for headless checking without approval.

## Toolchain

- WezTerm embeds Lua 5.4; system Lua may be 5.5. Use `bash scripts/lua.sh` or its
  explicit LUA override. No global Lua relinking. StyLua syntax is Lua54 and its
  read-only flag is --check, not --check-only.
- LuaLS annotations live in .lua-libs/wezterm-types, pinned by Justfile, and are
  editor-only. Never add them to runtime package.path or load them via plugins.
  Named `---@meta wezterm` resolves the native module statically.
- LuaLS headless checks need the configured absolute --metapath under .cache;
  relative paths can omit standard globals. Do not silence diagnostics broadly.
  A validated nullable table needs an explicit nullable declaration when required.
- Community declarations are not native API authority. The real color method is
  wezterm.color.get_builtin_schemes(), not get_builtin_color_schemes(). For new
  type seams, exercise a deliberate nonexistent API and verify diagnostics fail.

## Native tests must fail closed

`wezterm --config-file /absolute/harness.lua show-keys --lua` runs embedded Lua
without GUI, but can exit zero after a configuration error and render defaults.
Reuse scripts/smoke.sh and scripts/native-regressions.sh rather than accepting exit 0.
Require ALL: protected suite success, no failure diagnostic, strict builder native
conversion, and the expected test-only sentinel binding in rendered stdout.

Use xpcall with a tostring fallback when native debug.traceback is absent. Reassign
completed nested config tables to a fresh strict builder: mutating config.keys
can defer failure until after Lua reports success. Exercise outer syntax failure
and invalid nested modifiers as negative controls. Keep stderr diagnostics separate
from valid rendered strings such as SendString("ERROR").

Reuse real module logic with narrow native window/pane stubs. Native constructors,
formatting and `wezterm.emit` callbacks can be tested headlessly. Guard unexpected
process launches and non-query commands in harnesses. Do not globally type every
stub as the whole Wezterm API by redundantly assigning package.loaded.wezterm.

## Commands and scope

- `just fmt-check`, `just lint`, `just test`, `just smoke`; `just check` runs all.
- `bash scripts/native-regressions.sh` covers tests/*_native.lua.
- `bash tests/git_integration.sh` and `bash tests/git_safety.sh` use disposable
  real repositories, inert launchers and no remote connections.
- The default smoke fixture is tests/fixtures/smoke (offline/plugin-free).
  The separate test/ demo or personal WEZMACSDIR can run plugins; inspect before use.
- Raycast has extra npm gates in its own directory; load wezmacs-raycast.

### macOS developer-directory failure

A full-Xcode license prompt can arise inside nested /bin/sh -lc launches even
when the parent uses Homebrew Git; login PATH may resolve /usr/bin/git. Do not
accept agreements, use sudo or change xcode-select for a test. If separately
installed Command Line Tools work, first verify:
`env DEVELOPER_DIR=/Library/Developer/CommandLineTools /usr/bin/git --version`
Then use `DEVELOPER_DIR=/Library/Developer/CommandLineTools just check` for that
invocation only and disclose the override. If unavailable, report BLOCKED. Never
skip the failed test or call the plain command passing.

## GUI acceptance is separate

Headless green does not prove glyph rendering, key routing, focus, SSH auth,
remote sessions, TUI lifecycle or Nix/direnv loading. Use an explicitly requested
disposable fixture/window, clean Neovim and synthetic OSC/output, never a billable
agent or an existing live pane. Identify test ownership by config path and PID;
read its socket with lsof and set WEZTERM_UNIX_SOCKET on EVERY CLI call. --class
alone and inherited sockets are not isolation on macOS. Check inventory first.

A successful AppKit activation is not proof of frontmost placement. If loginwindow
is frontmost, report locked-session acceptance blocked; do not unlock. Capture
failures/0x0 images are not visual success or permission to bypass TCC. Clean up
only reverified test-owned processes and distinguish native versus visual evidence.
