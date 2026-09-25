---
name: wezmacs-mux-ssh
description: Use when changing workspace discovery, InputSelector, mux history, SSH/Tailscale pickers or native startup focus.
compatibility: OpenCode and other agents supporting repository-local skills
---

# Workspace, mux and SSH boundaries

Read docs/switchers.md and wezmacs/modules/mux/{init,workspaces,hosts}.lua.
Load wezmacs-validation. Recheck native version before generalizing findings
observed on 20250703-070941-c7f4b081.

## Workspaces

- Collect on picker opening, never config evaluation. Native live workspaces come
  first, then ranked zoxide, then sorted first/second levels of the configured
  root. Deduplicate canonical paths, preserve opaque IDs and literal paths.
- Raw shared choices stay undecorated; terminal UI owns color/icons. Explicit
  caller-supplied empty live inventory means none, not fallback to native lookup.
  Do not monkeypatch native mux enumeration in production adapters.
- Current live row is green, other live rows blue, entire icon AND name colored;
  reset afterward. Directory rows retain default foreground and aligned blanks.
  md_dock_window reserves at least two columns plus a separator because square
  glyph overflow can consume a following space. Regress one-/two-cell widths;
  '*' fallback uses one plus separator. Prefer effective ANSI colors.
- InputSelector uses fuzzy_description (`Workspaces: `, `SSH hosts: `) and separate
  description, not nonexistent help_text. Keep a trailing space and no key hints.
  Assert native fields before serialization; nested strings can escape spaces.
- Cancellation does nothing. Submission rechecks existence and current inventory.
  Reuse existing path-named workspaces; do not recreate closed previous workspaces.
- Native window_id can change when a GUI is repurposed for another mux window.
  History is GUI-client-wide (active_workspace is client-wide) in namespaced
  wezterm.GLOBAL, not keyed by mutable mux-window ID. Test remapping and reloads.

## SSH destinations and freshness

- Use native enumerate_ssh_hosts for literal aliases; preserve each alias and
  its deliberate User/ProxyCommand settings. Hashed known_hosts cannot be reversed;
  skip patterns, markers, malformed fields, keys and comments.
- Tailscale discovery is bounded shell-free status --json per opening, using the
  platform-supported timeout helper. No login/account switching or reachability
  probes. Optional failure retains static choices, not stale peer snapshots.
- Revalidate tailnet/self identity, peer ID and address on submit. Short labels
  may strip only the exact current MagicDNS suffix; pin full transport identity.
- Raw endpoints require explicit HostName, port (including 22), ProxyCommand=none
  as separate argv entries. Native alias matching can otherwise redirect raw
  selections even when peer identity is correct. Aliases themselves stay exact.
- Deduplicate against safely resolved endpoint, not alias spelling when HostName
  differs; distinct aliases retain different settings. Validate optional JSON
  types; reads can fail even after opening a known_hosts path successfully.
- Native literal IPv6 transport is not supported by the validated build's parser.
  Reject clearly; DNS/SSH aliases are the alternative. Do not claim parser checks
  prove a working connection.

## Native process and focus constraints

Native `wezterm ssh -- target` creates a separate GUI/plain-SSH connection;
no remote WezTerm daemon is needed. It cannot dynamically attach newly discovered
hosts as tabs in the original GUI. The validated mux API lacks runtime register/
remove domain support; reload and set_config_overrides are not reliable registry
updates. Do not add reload loops, generated domains, polling/mailboxes or remote
services to hide this. https://github.com/wezterm/wezterm/issues/7072

On the validated parser, `Include ~/.ssh/config.local` is not expanded; a sibling
`Include config.local` works. Compare native enumeration with ssh -G before
changing auth assumptions. SSH-file edits require separate approval. Native CLI
exit 0 can conceal remote exit 1: distinguish spawn, auth and command success.

macOS SSH focus uses startup gui-attached and exact-own-PID AppKit activation,
not recurring focus stealing. Tagged Raycast local startup defers once to
update-status: native start --domain can hold a mux lock during gui-attached.
Clear its request before activation; never simplify away this deadlock boundary.

Regressions: hosts_test.lua, workspaces_test.lua, mux_test.lua,
workspaces_native.lua and raycast_bridge_test.lua. No real SSH acceptance without
explicit authorization and user authentication; no employer hosts.
