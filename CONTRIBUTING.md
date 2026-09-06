# Contributing

Keep the framework small. Plain Lua modules, explicit load order and the native
WezTerm API are preferable to a plugin manager, dependency graph or generic event bus.

## Development checks

```sh
just types      # pinned, annotation-only wezterm-types checkout
just test       # regressions and smoke-checker negative case
just smoke      # real embedded Lua/native API, no GUI
just lint       # LuaLS Warning-or-higher diagnostics
just fmt-check  # read-only StyLua check
just check      # all gates
just fmt        # intentionally rewrite formatting
```

See the README for development tool installation. The system `lua` may be 5.5;
use `bash scripts/lua.sh` (or `LUA=/path/to/lua5.4`) so tests target WezTerm's 5.4.
LuaLS annotations cannot prove that a newer API exists in an older installed
WezTerm. Keep the native smoke gate and consult the official API documentation.

## Adding or changing a module

1. Read [FRAMEWORK.md](FRAMEWORK.md) and an existing module.
2. Add a failing regression for the behavior before changing runtime code.
3. Put built-ins under `wezmacs/modules/<name>/init.lua`; do not add categories
   or change existing identifiers merely to rearrange files.
4. Keep `opts`, `keys(opts)` and `setup(config, opts)` distinct. Supply module
   options in `modules.lua`, not nested sections of global `config.lua`.
5. Update relevant documentation and fixtures. External command dependencies
   must be documented; declaring `deps` does not install/check them.
6. Run `just check`. For plugin changes also run `WEZMACSDIR="$PWD/test" just smoke`.
7. Test interactive behavior in a disposable pane before claiming GUI validation.

## Test boundaries

`tests/*_test.lua` are standalone Lua programs. They exercise actual framework
code, with a narrow `package.loaded.wezterm` substitute where the Rust-hosted API
cannot exist in ordinary Lua. Each runs in its own process. Prefer simple
assertions to a large mock framework. Temporary test output must be cleaned up
and may never overwrite user configuration.

`tests/fixtures/smoke/` uses only built-in colors and non-plugin modules. The
smoke wrapper calls `wezterm show-keys --lua`; it requires both a completion marker
and a test-only sentinel binding in the rendered output. The latter proves native
conversion did not silently fall back to defaults despite exit status 0.
The `test/` directory remains the full, plugin-backed **interactive demo**.
Neither fixture proves actual keystroke routing, window focus, remote domains
or TUI process behavior. Those need explicit GUI tests when those features change.

## Style and safety

- StyLua is authoritative: tabs, 120-column limit, double-quoted strings.
- Keep validation failures visible and contextual. Do not swallow them to obtain
  a green check or silently replace malformed user settings with defaults.
- Do not add blanket LuaLS diagnostic suppression for the native module. Extend
  editor-only annotations or validate a documented API mismatch first.
- Command strings passed to action helpers are trusted shell programs. Do not
  interpolate unquoted filenames, branch names or prompt input into them.
- Preserve unrelated bindings and appearance. GUI/mux objects are distinct:
  methods available on a GUI Window are not automatically available on a MuxWindow.
- Keep types, logs and caches out of runtime imports and Git.
- No automatic commits, credential files, repository-scoped MCP servers or
  agent/worktree orchestration. Agent notification integrations live globally.
