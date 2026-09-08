# WezMacs

A small, modular WezTerm configuration framework inspired by Doom Emacs.
WezTerm owns the windows, tabs, panes and multiplexing; WezMacs composes Lua
settings and mnemonic key tables. No agent manager or extra multiplexer is required.

## Install and configure

Back up any existing `~/.config/wezterm` before cloning:

```sh
git clone https://github.com/ryantking/wezmacs ~/.config/wezterm
cd ~/.config/wezterm
just init
```

`just init` generates `config.lua` and `modules.lua` and **refuses to overwrite
either existing file**. User configuration is separate from the framework:

1. `$WEZMACSDIR`, if set
2. `$XDG_CONFIG_HOME/wezmacs`, if set
3. `$HOME/.config/wezmacs`

`config.lua` contains **global framework settings**, not per-module sections:

```lua
return {
  color_scheme = "Tokyo Night",
  term_mod = "LEADER",
}
```

`modules.lua` selects modules in application order and supplies their options:

```lua
return {
  "app",
  "mouse",
  { "term", opts = { font = "Iosevka Mono", font_size = 24 } },
  { "window", opts = { font = "Iosevka", font_size = 18 } },
  "tabs",
  { "mux", opts = { term_mod = "CTRL|SHIFT", term_alt_mod = "CTRL|SHIFT|ALT" } },
  { "edit", opts = { editor = "hx", file_manager = "yazi" } },
  "git",
}
```

Module identifiers are strings or the first array element: `{ "git", opts = ... }`.
See [FRAMEWORK.md](FRAMEWORK.md) for the exact contract. There is no custom-module
search directory or dependency installer hidden behind this interface.

## Modules

| Module | Responsibility |
|---|---|
| `app` | Application actions, leader configuration, miscellaneous TUI launchers |
| `term` | Terminal behavior, text fonts, clipboard/search/scrollback |
| `window` | Decorations, padding, UI fonts and theme application |
| `tabs` | Tab navigation and title rendering |
| `mouse` | Selection and mouse behavior |
| `mux` | Native panes and workspace/SSH host pickers |
| `edit` | Editor, IDE, Yazi and file-search launchers |
| `git` | Lazygit and related Git tool launchers |

The old agent/worktree integration has been removed. Claude Code/OpenCode can
run as ordinary terminal programs; their global settings and notifications are
outside this repository. No agent binaries, credentials, hooks or MCP servers
are installed by WezMacs.

`mux` owns workspace and SSH-host helpers and has no plugin dependency. The default
Rose Pine theme uses [neapsix/wezterm](https://github.com/neapsix/wezterm).
WezTerm fetches these plugins on first use. A built-in theme plus the offline
smoke fixture avoids network-dependent plugin loading during core validation.
External TUI executables are installed separately; `deps` module fields are
informational, not an availability check.

## Switchers

With the default macOS leader, press **Cmd-Space**, release, then the final key:

| Key after Leader | Action |
|---|---|
| `s` | Workspaces: active sessions, ranked zoxide paths, then two levels below `~/Workspaces` |
| `S` (Shift-s) | Toggle to the previous workspace |
| `d` | SSH hosts: SSH aliases, readable known hosts and current-tailnet peers; native SSH in a new window |

Both main pickers refresh when opened. Type to fuzzy-filter, Enter to select,
Escape to cancel. Leader-Space remains the file-search launcher. The former
advanced-domain shortcuts (`D`, `|`, `_`) are unbound; native domain configuration
and `wezterm connect` remain available without a plugin. See
[switcher behavior, configuration and manual tests](docs/switchers.md).

## Raycast launcher

The optional [Wezterm Raycast extension](raycast/README.md) lives in `raycast/`
and exposes **Open Workspace** and **SSH to Host**. It uses the same Lua discovery
and SSH planning helpers as the terminal pickers, with explicit typed directory
and SSH-target fallbacks. **Open Workspace always opens a fresh local shell in a
new independent window**, leaving existing windows unchanged. It does not clone
workspace layouts. It is a local extension: install it separately on each
Mac; Raycast Cloud Sync is not a source-code deployment mechanism.

## Development

The runtime is WezTerm's embedded **Lua 5.4**, not LuaJIT or Neovim Lua.
The lean development stack is **Lua 5.4 + StyLua + LuaLS + just**.

```sh
just deps       # macOS/Homebrew development tools + pinned type annotations
just check      # formatting check, LuaLS diagnostics, regressions, native smoke
just fmt        # explicit formatting write
just demo       # explicitly opens a separate WezTerm process with test/ config
```

No runtime LuaRocks packages are required. On other platforms install the tools
with your package manager and run `just types`. `scripts/lua.sh` finds a Lua 5.4
executable; set `LUA=/path/to/lua5.4` if necessary. It does not relink your global
Lua. Homebrew's `lua@5.4` is deprecated upstream; it is used deliberately to match
the terminal's embedded runtime, not as a recommendation for new standalone Lua apps.

LuaLS reads `.luarc.json` and the pinned [wezterm-types](https://github.com/DrKJeff16/wezterm-types)
annotations in `.lua-libs/`. Those files are **editor-only**. They are never added
to WezTerm's runtime `package.path`, and no fake `wezterm.lua` shadows the native
API. Open the repository as the editor's workspace root. After `just types`, a
LuaLS-capable editor can resolve WezTerm APIs without launching WezTerm.

`just check` does not format or change source files. LuaLS may write diagnostic
reports under ignored `.cache/`. Tests use temporary fixtures, do not open GUI
windows, and do not launch agents or installed TUI applications. Native smoke
validation requires the actual `wezterm` executable and rejects fallback to a
default configuration. It is not a GUI navigation test.

To validate the full plugin-backed demo or personal config without opening a GUI:

```sh
WEZMACSDIR="$PWD/test" just smoke
WEZMACSDIR="$HOME/.config/wezmacs" just smoke
```

Update intentionally with Git after reviewing local changes. There are no
self-updating, self-uninstalling or autocommitting recipes.

- [Architecture and module contract](FRAMEWORK.md)
- [Contribution and testing guide](CONTRIBUTING.md)
- [Core audit and remaining debt](docs/core-audit.md)

## License

See [LICENSE](LICENSE).
