# Framework architecture

## Composition

```text
wezterm.lua                     native config builder + ordered application
  └─ wezmacs/init.lua           public API and global configuration discovery
       ├─ config.lua           defaults + optional personal config.lua
       ├─ module.lua           modules.lua parsing, contracts and merging
       ├─ keys.lua             key-map compiler and description ownership
       └─ action.lua           terminal launch helpers
            └─ modules/*       feature-specific opts, keys and setup
```

`~/.config/wezterm` is the framework checkout. Personal files normally live in
`~/.config/wezmacs`; `WEZMACSDIR` and `XDG_CONFIG_HOME` take precedence as described
in the README. These two directories have different roles and must not be merged.

### Load sequence

1. Extend the Lua search path for the framework checkout, not editor annotations.
2. Load global settings through `wezmacs.config.load`.
3. Create a native WezTerm builder with strict validation enabled.
4. Read the ordered module list.
5. For each module, validate the contract, resolve defaults/overrides and key maps,
   run setup, then append compiled bindings.
6. Return the native config. Errors must not be reported as successful loading.

Configuration evaluation is not a place to start agents, perform expensive
process discovery or silently update global settings.

## Global configuration

`config.lua` returns a flat table of framework settings. Defaults are in
`wezmacs/config.lua`: `color_scheme`, `term_mod`, `gui_mod`, `ctrl_mod`, `alt_mod`,
`shell`, and a detected `platform`. Module-specific settings belong in the
corresponding `modules.lua` entry, not nested global sections.

A missing optional `config.lua` uses defaults. A present but malformed file,
execution failure, invalid return value or non-missing read failure is an error.
Do not make these cases indistinguishable by returning an empty table.

## Module contract

Built-ins live at `wezmacs/modules/<name>/init.lua`. The loader uses
`require("wezmacs.modules." .. name)`. There is no automatic custom-directory
search, module dependency scheduler, lazy-loader, installation phase or external
binary availability checker.

`modules.lua` is an ordered sequence:

```lua
return {
  "app",
  { "term", opts = { scrollback_lines = 10000 } },
  { "git", opts = { diff_branches = { "main" } } },
}
```

A module specification is a table:

```lua
local wezterm = require("wezterm")

return {
  name = "example",
  description = "One cohesive feature",
  deps = {}, -- informational list of external executables
  opts = { scrollback_lines = 10000 },
  keys = function(opts)
    return {
      { key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration, desc = "reload" },
    }
  end,
  setup = function(config, opts)
    config.scrollback_lines = opts.scrollback_lines
  end,
}
```

- `opts`: table or zero-argument function returning a table.
- `keys`: table or function receiving resolved options and returning a table.
- `deps`: table or function receiving resolved options and returning a table.
- `setup`: optional function `(config, opts)`; absent means no-op.
- A user entry may override all of these fields. Built-in setup runs before user
  setup, with the same config and resolved options.
- `name` in an entry is its first positional value, not `{ name = "git" }`.
- Module load/evaluation failures include the module and phase where available.
  No partially resolved module is returned as a valid result.

### Merge semantics

Keep data shapes distinct:

- Option maps recursively merge. Scalar values replace defaults.
- Sequence/numeric option tables replace as a whole: a shorter `diff_branches`
  list does not retain the old tail. An explicit empty table clears a default
  sequence, while an empty map override leaves named defaults intact.
- Inputs are copied rather than shared with cached module defaults.
- Key maps merge named groups. A supplied numeric binding list replaces that
  group's numeric defaults, not its unrelated named groups.
- Binding/action specifications replace atomically. Never deep-merge native
  action variants such as `SendString` and `CopyTo` into the same table.

This is not a key-by-key reconciliation engine. To replace a numeric menu list,
supply the desired complete list. An explicit `keys = {}` clears all keys for a
module; an empty named group clears that group. There is no separate
deletion/tombstone DSL.

## Key-map grammar

```lua
{
  { key = "r", mods = "CTRL", action = act.ReloadConfiguration, desc = "reload" },
  LEADER = {
    r = { action = act.ReloadConfiguration, desc = "reload" },
    g = {
      { key = "g", action = act.ActivateCopyMode, desc = "copy" },
      x = { action = act.ActivateCopyMode, desc = "copy" },
      m = { x = { action = act.ActivateCopyMode, desc = "nested-copy" } },
    },
  },
}
```

- Numeric entries are direct `{ key, mods?, action, desc? }` bindings.
- Mapped action specs are leaves; mapped tables without an action spec are menus.
- Only the root `LEADER` group adds the LEADER modifier. Keys inside an activated
  table do not require the leader again.
- A leaf executes its action and pops the current table. A generated submenu
  activation stays active; Escape pops one table level. Deeper menus return to
  their parent rather than clearing an unrelated external key-table stack.
- Numeric keys are sorted by index, then mapped entries by key, making output
  deterministic. This preserves list-before-map precedence, not collision detection.
- Existing one-level names such as `git_LEADER_g` remain stable.
- `get_descriptions()` returns path-to-description metadata;
  `get_module_descriptions(name)` uses explicit module ownership. Latest
  registration of a path owns its description.

No conflict UI or platform/editor routing is implied. In particular, seamless
Neovim/terminal movement requires the later smart-splits bridge, not just this
compiler.

## Actions and runtime boundaries

`SmartSplit(command)` returns a callback that chooses Bottom/Right by window
aspect ratio. `NewTab(command)` and `NewWindow(command)` return native actions.
Each command is a **trusted shell program**, executed through the configured
shell with `-lc` for its login environment. The shell exits after the complete
program; compound fallback expressions must not be prefixed with `exec`.
These helpers do not sanitize untrusted strings or turn a command into an argv list.

`wezmacs.color_scheme()` lazily resolves the selected theme. The current built-in
lookup is `wezterm.color.get_builtin_schemes()`. The default Rose Pine theme and
mux adapters have separate plugin dependencies; see the README.

Native WezTerm objects are not interchangeable: a Pane, MuxTab, MuxWindow and GUI
Window expose different methods. Keep mocks narrow and retain real native
smoke validation alongside unit tests.

## Testing and remaining design debt

See [CONTRIBUTING.md](CONTRIBUTING.md) for commands/test boundaries and
[docs/core-audit.md](docs/core-audit.md) for deferred module-level issues. The
framework does not require Neovim, a test framework package, agent credentials
or an additional multiplexer to develop or validate its core.
