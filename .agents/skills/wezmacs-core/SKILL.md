---
name: wezmacs-core
description: Use when planning or changing WezMacs core, modules, configuration, keys, actions or session handoffs.
compatibility: OpenCode and other agents supporting repository-local skills
---

# WezMacs core and orientation

## Start here

Read AGENTS.md, FRAMEWORK.md, CONTRIBUTING.md and docs/agent-workflow.md. Inspect
Git status/diff including untracked files before editing. Read the relevant active
OpenSpec change and handoff if any. Current source wins over stale session notes;
record discrepancies rather than silently implementing a remembered plan.

The entrypoint is wezterm.lua; wezmacs/init.lua exposes the API, config.lua loads
flat global options, module.lua resolves ordered feature modules, keys.lua compiles
menus, action.lua owns trusted launch helpers, and theme.lua resolves palettes.
Personal config normally lives in ~/.config/wezmacs, not in this framework checkout.
Read actual precedence in config/init and README before changing discovery.

## Contracts to preserve

- Keep built-ins at wezmacs/modules/<name>/init.lua. The ordered modules.lua list
  uses strings or { "name", opts = {...}, setup = function(...) ... end }.
  No custom-directory search, dependency scheduler, auto-install or lazy-loader
  exists. deps is informational, not an availability check.
- Global config is flat. Module-specific options belong in the module entry.
  Missing optional config uses defaults; malformed/unreadable existing config
  must fail with useful context. Do not catch every error and return {}.
- Module opts can be a table or zero-argument function. keys/deps functions receive
  resolved options. Built-in setup runs before user setup with the same config/options.
- Maps merge recursively; sequences replace wholesale (no retained tails).
  Copy inputs/defaults. Explicit empty sequences clear them. Empty option maps
  retain map defaults. Key-map numeric lists replace at their group; named groups
  merge. keys={} clears all module keys; an empty named group clears that group.
- Native action/ColorSpec variants replace atomically, never recursively combine.
- Numeric bindings sort by index before mapped entries sort by key. Root LEADER
  alone adds its modifier. Nested activation remains active; leaves and Escape
  pop one level, not the whole external table stack. Description ownership is
  explicit; deterministic order is not a conflict-resolution UI.
- Preserve existing identifiers and effective Colemak/Moonlander direction keys.
  Read code rather than copying QWERTY h/j/k/l. Current switcher keys are in
  docs/switchers.md; do not blindly carry older session mappings into this repo.
- Trusted compound shell programs use the configured shell with -lc. Do not
  prefix `first || fallback` with exec: replacement prevents the fallback.
  Untrusted selections use argv, not these shell-program helpers.
- Pane, MuxTab, MuxWindow and GUI Window are different native object types.
  Check the real method before adding it to a mock.

## Boundaries and regression map

Use wezmacs-validation for every change. Core tests include config_test,
module_test, keys_test, action_test, bootstrap_test and generator_test under tests/.
No extra Busted/LuaRocks layer is needed for these assertion-based tests.

Do not reintroduce agent launchers, worktree lifecycle ownership, generic event
buses or a second pane system. Contributor-side OpenSpec tooling is not a runtime
WezMacs feature. Read docs/core-audit.md for deferred debt: option validation,
key conflicts, close policy and editor/smart-splits integration are not completed
merely because they appear in that document. Do not change them without scope.

At handoff, write change/task IDs, owned paths, actual checks/exits, known failures,
next safe action and approval boundaries in the active change, not this skill.
