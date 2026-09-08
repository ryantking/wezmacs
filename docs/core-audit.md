# Core audit

## Decision

**Retain WezMacs and its flat module layout.** The useful abstraction is small:
resolve global settings, load ordered module specifications, combine options,
apply native WezTerm settings, and compile mnemonic key tables. The defects were
concentrated in those contracts and their validation, not in the overall choice
of Lua or modular configuration.

Do not add a generic dependency graph, service container, agent manager or a
second pane/tab system. Keep terminal-owned agent sessions and later Neovim
integration separate from this foundation pass.

## Architecture assessment

| Area | Assessment |
|---|---|
| Entrypoint | Appropriate thin composition root. Native builder should validate strictly; failed modules must not produce a success announcement. |
| Global configuration | Separate personal directory is valuable. Missing optional settings and malformed existing settings must be distinct outcomes. |
| Module organization | Feature directories are appropriate at this size. Keep existing names and load order. `deps` is metadata, not a scheduler or executable check. |
| Key compiler | The original repeated conversion branches had diverged. A single recursive traversal is easier to reason about and regression-test. |
| Action helpers | A sensible shared boundary, but executable launches and compound shell programs have different semantics. |
| Tooling | The old recipes were unreliable: nonexistent entrypoint, invalid formatter flag, suppressed lint errors, and GUI launch masquerading as a test. |
| Documentation | Substantial drift: unimplemented custom-module discovery, nonexistent files/functions, invalid module syntax and options. Document the implemented contract instead of adding features to match old prose. |

## Defects addressed in this pass

- User `setup`/`deps` overrides were discarded; composed setup also called the wrong object.
- Shorter option arrays retained trailing default values; native action payloads could be merged into invalid multi-variant tables.
- Missing/invalid module contracts lacked contextual errors, and broken user configuration could silently fall back to defaults.
- Mapped submenu leaves disappeared; deeper menu activations received another LEADER modifier and immediately popped their newly activated table.
- Numeric key iteration and description ownership were unreliable.
- Prefixing compound shell commands with `exec` prevented Git fallback expressions from running.
- The move-pane-to-window action called nonexistent `MuxWindow.activate`; it now uses the GUI window's focus API.
- Deprecated color lookup and obsolete icon identifiers were caught by LuaLS/native checks.
- The configuration generator could overwrite existing personal settings and did not share runtime directory precedence.
- Legacy agent/worktree launchers, global input workarounds belonging to that module, repository MCP configuration and copied agent scaffolding were removed. Generic contributor instructions remain in `AGENTS.md` with a one-line Claude import; no hooks or orchestration are installed.

## Validation model

1. Standalone Lua 5.4 regressions exercise real framework logic with narrow mocks at the Rust-hosted API boundary.
2. LuaLS resolves native WezTerm declarations through a pinned development-only library; a deliberately nonexistent API was verified to fail diagnostics.
3. StyLua enforces Lua 5.4 syntax and the existing formatting convention.
4. Native smoke checks load the actual configuration with WezTerm's embedded Lua and strict native config builder. A separate deliberately broken configuration verifies failure detection.
5. Full plugin-backed demo and copied personal settings are checked separately from the offline fixture.
6. Rendered key assignments are compared to the original configuration, normalizing generated callback IDs. This checks keymap preservation, not callback runtime equivalence.

`just check` must return nonzero for failures and must not modify source files.
Native smoke is not a claim that GUI focus, real key presses, process lifecycle,
remote domains or Neovim navigation were exercised. No CI service was connected
or remote workflow run by this pass.

## Remaining debt / next boundaries

- **Module responsibility overlap:** `app` mixes core application/leader settings with miscellaneous launchers; `term` and `window` overlap in appearance concerns. Keep this stable now; split only when a concrete feature makes the boundary useful.
- **Plugin adapters — addressed in the switcher pass:** workspace and SSH discovery now live in two small `mux` helpers. The workspace helper replaces the plugin's unsafe shell-concatenated zoxide calls; binary paths are configurable with GUI PATH fallbacks. The mux module no longer requires a plugin; the advanced domain picker and unused workspace mailbox have been removed. One active-workspace status callback replaces the duplicated, theme-dependent handlers. See [switcher design and tests](switchers.md).
- **Configuration diagnostics:** arbitrary per-module option keys are not schema-validated. The personal `enable_kitty_keyboard = false` is under `mux`, where it has no effect; the effective setting remains the `term` default. This pass intentionally does not change keyboard behavior by moving it.
- **Dependency metadata:** some declared TUI dependencies are stale or incomplete. There is no launcher availability check. Audit actual launchers before rebuilding the editor/agent workflow.
- **Key conflicts:** existing modules can target the same chord (for example LEADER-Space in `term` and `edit`). Deterministic ordering is not a conflict-resolution UI; preserve current effective bindings for now.
- **Close policy:** current configuration disables several close confirmations. Revisit deliberately before putting long-running agents into the new workflow.
- **Review/focus/navigation:** Neovim smart-splits, editor-agent handoff, safe ephemeral Yazi/lazygit surfaces and global agent notifications remain separate implementation tasks.
- **Release/tool pinning:** WezTerm's installed build is the compatibility authority. The annotation revision is pinned; local tool versions are documented, not a fully locked cross-platform CI environment. Homebrew's Lua 5.4 formula is deprecated but currently usable for runtime-aligned tests without replacing system Lua 5.5.

## Sources

- [WezTerm Lua reference](https://wezterm.org/config/lua/general.html)
- [Native config builder](https://wezterm.org/config/lua/wezterm/config_builder.html)
- [Headless key assignment command](https://wezterm.org/cli/show-keys.html)
- [GUI window focus](https://wezterm.org/config/lua/window/focus.html)
- [Current color lookup API](https://wezterm.org/config/lua/wezterm.color/get_builtin_schemes.html)
- [LuaLS definition files](https://luals.github.io/wiki/definition-files/)
- [Community WezTerm type annotations](https://github.com/DrKJeff16/wezterm-types)

Local findings are based on the original `3478481` source and executable regression probes, not inferred from those web references.
