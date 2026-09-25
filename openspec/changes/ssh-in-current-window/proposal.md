# Proposal

## Why

The terminal SSH picker currently duplicates Raycast by launching a separate native `wezterm ssh` window. Internal shortcuts should instead modify the current window, while Raycast remains the entry point for independent windows.

## What Changes

- **BREAKING**: Default `leader d` changes from a new-window native SSH launch to system OpenSSH in a right-hand, 50% split of the current tab.
- Add default `leader D` for system OpenSSH in a new tab of the current window.
- Retain the existing host picker, discovery timing, cancellation, alias preservation, endpoint validation, and Tailscale identity freshness checks.
- Keep Raycast and its native SSH launch-plan contract unchanged.
- Require a local originating pane, with an explanatory notification otherwise; do not accidentally run the SSH client on a remote mux domain.
- Document that internal launches follow OpenSSH configuration/authentication semantics rather than WezTerm's native SSH parser. The user approved this transport change and the right-hand split convention.

## Capabilities

### New Capabilities

- `terminal-ssh-placement`: In-window SSH split/tab placement, safe local OpenSSH launch planning, picker lifecycle, and compatibility with the existing Raycast window path.

### Modified Capabilities

None. The only maintained spec currently covers contributor workflow, not terminal SSH behavior.

## Impact

- Runtime: `wezmacs/modules/mux/hosts.lua` and `wezmacs/modules/mux/init.lua`.
- Regression seams: `tests/hosts_test.lua`, `tests/mux_test.lua`, a focused `tests/hosts_native.lua`, and existing Raycast bridge coverage.
- Documentation: `docs/switchers.md`, relevant shortcut references in `README.md`, and any affected SSH contract text in `FRAMEWORK.md`.
- Uses existing system OpenSSH; no new installed dependency, shell wrapper, or runtime service.
- Compatibility boundaries: native `hosts.launch_args()` remains suitable for Raycast; unrelated bindings, appearance, module option merging, and personal overrides remain unchanged.
- Non-goals: remote-pane spawning, dynamic SSH domains, remote WezTerm daemons, domain reload/cache machinery, new discovery sources, IPv6 support expansion, SSH-file edits, Raycast changes, and configurable split layouts or executable options.
- Planning only. Implementation requires a subsequent explicit apply request; GUI/network acceptance requires separate authorization and must not touch existing live panes.
