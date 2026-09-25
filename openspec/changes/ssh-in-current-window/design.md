# Design

## Context

See `proposal.md` for motivation and `specs/terminal-ssh-placement/spec.md` for acceptance requirements. Today `wezmacs/modules/mux/init.lua` binds only `leader d` to `hosts.switch_host(opts.hosts)`. In `hosts.lua`, `launch_args()` validates selection data and Tailscale freshness, then produces native `wezterm ssh` arguments; the picker sends them to `background_child_process`.

The native CLI creates a separate GUI/plain-SSH connection. `docs/switchers.md` records that dynamic discovery cannot be reliably converted into runtime SSH domains on the validated native build. Running `wezterm ssh` inside a split therefore would not meet the request. The user explicitly approved ordinary system OpenSSH for internal launches and a right-hand 50% split.

Existing `wezmacs/modules/git/launch.lua` demonstrates `SplitPane` and `SpawnCommandInNewTab`; `git/actions.lua` establishes the local-pane guard convention. The Raycast bridge consumes the native `hosts.launch_args()` contract independently. The checkout had no tracked modifications at discovery; untracked workflow files and the preexisting OpenSpec root are unrelated user work.

## Goals / Non-Goals

**Goals:** Keep discovery/validation shared, separate transport argv planning, and reuse native placement actions without introducing a launch framework. Prove action conversion using the real embedded runtime, not just Lua mock shapes.

**Non-Goals:** No dynamic domains, shell command strings, SSH configuration edits, remote-domain launch support, new module options, extra SSH discovery features, or Raycast implementation changes. Existing literal IPv6 rejection remains unchanged despite OpenSSH's broader capabilities.

## Decisions

### Separate transport planning while preserving the native contract

Keep `hosts.launch_args()` compatible with existing native/Raycast callers, including its options, error behavior, executable selection, and raw-target flags. Add a separate OpenSSH argument planner in `hosts.lua`. Extract only the minimum shared validated-selection step if needed, so each submission performs freshness validation once rather than launching through or deriving arguments from a native command.

Use the system `ssh` executable through a direct argv action whose first entry is the literal `ssh`, with normal executable lookup and no shell wrapper or new executable configuration option. Do not hardcode macOS-only paths into the otherwise portable module. For configured aliases, keep the destination literal and leave deliberate OpenSSH settings intact. For raw endpoints, pass explicit `HostName`, explicit `-p` port (including 22), `ProxyCommand=none`, and `ProxyJump=none`; use validated `user@host` as the destination when a username is present and validated `host` otherwise. Terminate options before the destination. Do not pass `host:port` as OpenSSH's destination.

Do not disable all SSH configuration with `-F /dev/null`: authentication identities and agent settings remain useful. Raw transport pinning applies only to non-alias selections. Preserve current parsing, serialization checks, optional-source degradation, and Tailscale peer/self identity revalidation. A transport-specific planner is preferred to modifying native argv in place because native and OpenSSH semantics differ and Raycast must not change.

### Placement stays within the existing mux module

Extend the terminal picker action with explicit split/tab placement, defaulting to split for the existing single-argument call. Bind `d` and `D` in `mux/init.lua`, with distinct key descriptions consistent with nearby bindings. Retain module option resolution and key-map override behavior.

For a valid local pane, perform a `SplitPane` action with direction `Right`, size `Percent = 50`, and the OpenSSH spawn command, or `SpawnCommandInNewTab` with the same spawn command. Follow the existing `window:perform_action(action, pane)` pattern. Never use `background_child_process`, `SendString`, or `wezterm ssh` for this path. Do not add an idle shell wrapper to keep a terminated SSH process alive; normal pane-exit behavior remains controlled by existing WezTerm configuration.

### Require a local origin rather than inheriting an arbitrary domain

Require `pane:get_domain_name()` to report `local` both before picker opening and before submission. Missing/unreadable domain identity fails closed with a notification. Once checked, use the existing `CurrentPaneDomain` spawn-action pattern. Do not trust a remote domain just because its current-directory URL looks local; SSH placement needs no Git-directory probing.

This deliberately follows the Git guard convention rather than silently switching domains. It avoids executing the client on a remote server or relying on unverified explicit-domain split behavior. A session started by this feature is itself a local OpenSSH process, so its pane remains eligible for subsequent SSH shortcuts. Already attached native remote-domain panes are unsupported by this change and must be documented as such.

### Preserve picker lifecycle and report failures honestly

Keep discovery on opening, fuzzy prompt `SSH hosts: `, existing label decoration, and a no-op cancellation path. Validate before constructing any placement action. Invalid/stale selections and unsupported domains notify without creating a pane/tab. Use existing notification conventions for synchronous action errors; do not claim that successful action dispatch proves authentication, remote command success, or even eventual process startup. Authentication and asynchronous OpenSSH errors belong to the spawned terminal, without fallback to an independent window.

### Regression and native evidence

- `tests/hosts_test.lua`: preserve native argv coverage; add OpenSSH alias/raw-port/proxy options, invalid payloads, unsupported IPv6, stale peer identities, local-domain guard/recheck, fresh discovery, cancellation, split/tab action capture, and immediate action failure without background spawning.
- `tests/mux_test.lua`: assert both default bindings and intended placement routing; retain unrelated binding/override coverage.
- New `tests/hosts_native.lua`: exercise real native constructors and real picker callbacks using narrow local-pane/window stubs; forbid process launch and network calls. Follow `tests/git_native.lua` and the existing protected-suite, strict-builder, completion-marker, rendered-sentinel harness. `scripts/native-regressions.sh` already discovers `*_native.lua` files.
- Existing `tests/raycast_bridge_test.lua`: unchanged compatibility gate for the native bridge contract. No Raycast source or TypeScript changes are planned.
- Documentation: update `docs/switchers.md` and affected `README.md`/`FRAMEWORK.md` references to separate internal OpenSSH from native Raycast windows.

The required offline commands are `bash scripts/lua.sh tests/hosts_test.lua`, `bash scripts/lua.sh tests/mux_test.lua`, `bash scripts/lua.sh tests/raycast_bridge_test.lua`, `bash scripts/native-regressions.sh`, and `just check`. The independent tester runs these after the coder finishes. Real constructors are native-version-sensitive; installed type annotations alone are not sufficient evidence.

## Risks / Trade-offs

- [OpenSSH and native SSH parse configuration differently] → User approved the transport change; document it and preserve literal aliases rather than rewriting their intended configuration.
- [Raw hostname matching could inherit unwanted routing] → Explicit hostname/port and both proxy-disabling options; test command options without contacting a real host.
- [Remote domain inheritance could execute locally intended commands elsewhere] → Check local identity on opening and submission, with negative coverage.
- [Shared validation extraction could alter Raycast semantics] → Preserve native argv tests and rerun bridge tests; do not refactor unrelated discovery code.
- [User key overrides may replace defaults] → Do not edit personal settings; document default bindings only.
- [Headless checks cannot prove window placement, focus, or authentication] → Require separately authorized disposable GUI acceptance and record blockers explicitly.

## Migration Plan

After proposal approval, add failing regressions, implement the bounded mux changes, and independently verify them. Update feature docs after behavior verification, then rerun final checks. No dependencies or personal settings are installed or changed. Normal configuration reload makes the changed defaults available when implementation is complete; do not force a reload of a live session as a test.

Rollback consists of reverting only this change's mux code, tests, and documentation, restoring the prior `leader d` new-window behavior and removing the new default `D` binding. Do not revert unrelated untracked workflow files. No automatic commit, archive, or release is authorized.
