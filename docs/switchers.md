# Workspace and SSH switchers

## Keys to test

On the default macOS configuration, **Leader is Cmd-Space**. Release the chord,
then press the following key. Uppercase means Shift plus that letter.

| Sequence | Result |
|---|---|
| Cmd-Space, `s` | Main workspace picker |
| Cmd-Space, `S` | Previous workspace, following native GUI-client workspace scope |
| Cmd-Space, `d` | Fresh SSH host picker → native WezTerm SSH in a new window |
| Cmd-`r` | Reload configuration |

Type immediately to fuzzy-filter; Enter accepts and Escape cancels. These are
sequences, not simultaneous Cmd-Space-letter chords. Leader-Space remains file
search. Pane direction/resize shortcuts and other modules are unchanged.

## Workspace behavior

The picker combines, in priority order:

1. Active WezTerm workspaces. In the terminal picker, the current workspace
   comes first with `[current]`; other live workspaces show `[running]`.
   Folder candidates have no running marker. This uses native mux inventory,
   not a sessionizer dependency.
2. Existing, readable directories from `zoxide query -l`, in zoxide's order.
3. Directories at exactly the first and second levels below `~/Workspaces`,
   sorted by path: `~/Workspaces/group` and `~/Workspaces/group/project`.

All sources are refreshed on opening. The scan omits dot-directories and the
common generated-directory names `node_modules`, `target`, `build`, `dist`,
`__pycache__`, and `coverage`; this exclusion applies only to the directory scan,
not explicitly visited zoxide paths or active workspaces. Files, missing paths,
and unreadable directories are not offered as new workspace paths. No third
level is added by the scan, though a deeper directory can appear through zoxide.

Paths are deduplicated, including home abbreviation and trailing slash variants.
Choosing an existing workspace switches to it; choosing a new path opens a
local-domain workspace at that directory. Workspace names use the home-shortened
full path, not just the basename, so identically named projects do not collide.
Selection uses the stored path, not the displayed label. Spaces and shell
metacharacters are passed literally to zoxide as argv; no shell is involved.

Previous-workspace history is GUI-client-wide, matching native WezTerm workspace
scope. Its namespaced `wezterm.GLOBAL` value survives Lua reloads and changing
mux-window IDs. A closed previous workspace is not recreated. A cancelled picker
does not change history, spawn a process or alter zoxide history. Discovery does
not run during config loading.

## SSH host behavior

The normal SSH picker combines:

- Literal aliases returned by WezTerm's SSH configuration parser, including
  supported `Include` files. Wildcard/negated host patterns are not targets.
- Readable literal hostname fields in `~/.ssh/known_hosts`. Hashed entries,
  markers, wildcard patterns and malformed endpoints are omitted. This is not
  a reversible inventory of previously visited machines: hashed hostnames cannot
  be recovered by enumeration. Add a normal `Host` alias yourself for a machine
  that should always appear.
- Peers from the **currently active** `tailscale status --json` response. The
  picker shows the tailnet and online/offline state. Location-tagged provider
  exit nodes and this machine are excluded; personal exit nodes are retained.

Configured aliases retain their SSH settings and are preferred over equivalent
raw addresses. Different aliases remain distinct because they can represent
separate users, keys or proxy settings. Tailscale peers under the current
MagicDNS suffix display and match SSH `User` rules using their short hostname.
The full FQDN remains the peer identity and explicit transport `HostName`, so a
same-named alias cannot redirect a Tailscale selection. Unrelated FQDNs and IPv4
fallbacks remain unchanged. Discovery
indicates a device exists, **not that it runs SSH or permits your login**; mobile
and offline peers may still be listed. No port probes are made.

Tailscale is queried on every open, with a three-second process deadline. Missing
CLI/timeout support, failed status, logged-out/stopped state and malformed output
leave the static SSH entries available and display a status explanation; old
peer results are not reused. If the tailnet/account or selected peer changes
while the picker is open, submission is rejected and the user must reopen it.
The picker never switches accounts, logs in, or modifies Tailscale settings.

### Why native SSH is a new window

Aliases use an argv invocation of `wezterm ssh -- target`, not a nested OpenSSH
process in a terminal pane. Raw discovered endpoints also receive an explicit
`HostName` override and port so a matching SSH-config alias cannot redirect the
represented destination. Inherited `ProxyCommand` is disabled for these raw,
direct destinations. Use a configured alias for a bastion/proxy route;
aliases retain their original settings.
On the validated build
`20250703-070941-c7f4b081`, that command starts a separate native WezTerm window
with plain SSH (`multiplexing = "None"`). The remote does not need WezTerm.
For SSH, `gui-attached` focuses the new active-workspace window.
On macOS it also activates that exact GUI process through an AppKit helper
addressed to its parent PID; native window focus alone does not make a background
process frontmost. This runs at startup only, not on status updates or config
reloads, and is shared by the terminal picker and Raycast launcher.
Remote sessions in that separate process are not workspaces in the original
local process; this is native CLI behavior, not a second multiplexer added by
WezMacs.

Static plain SSH domains can support tabs in the existing GUI, but dynamically
registering/removing them on each tailnet change is not a reliable public API on
this build. Do not add reload loops, generated config caches, domain lifecycle
state or remote services merely to hide that limitation. The former domain-picker
plugin and its `D`, `|`, `_` shortcuts are removed. Native domain configuration
and `wezterm connect <domain>` remain available for deliberate mux-server setups;
WezMacs does not generate or manage those domains.

The native SSH implementation supports only a subset of OpenSSH configuration.
It respects supported alias settings such as `User`, `Port` and `IdentityFile`;
otherwise the login user follows native SSH defaults. No guessed username,
password, host-key bypass, agent forwarding override or auth helper is added.
Authentication and host-key prompts remain for the user.

On `c7f4b081`, the WezTerm configuration parser does not expand `~` in
`Include` paths. For a sibling file, use `Include config.local` instead of
`Include ~/.ssh/config.local`. Confirm native enumeration returns the expected
`User` before assuming OpenSSH and native WezTerm use the same account. A native
SSH process can return exit 0 even when its remote command exits 1; inspect the
remote exit status rather than treating process spawning as connection success.

The installed native parser cannot safely launch IPv6 literals; those selections
show an explicit notice instead. Use a DNS name or an SSH alias backed by IPv6.

## Raycast workspace windows

Raycast's **Open Workspace** intentionally differs from the terminal switcher:
every acceptance opens a fresh local shell in a new independent GUI window,
leaving existing windows unchanged. It does not clone tabs, panes or programs.
Running indicators describe the addressed GUI's mux, not all independent GUI
processes. Path-based names open their directory; opaque names require a fresh,
existing local pane directory. An unavailable directory produces an error, not a
silent home-directory fallback.

Explicitly tagged Raycast windows request focus once on the first status update.
This avoids enumerating mux windows during local `gui-attached`, where the native
startup path can still hold a window lock. Subsequent status updates and config
reloads do not reactivate the window. See the [Raycast guide](../raycast/README.md).

## Configuration

Keep one `mux` module entry. Defaults work without personal config changes:

```lua
{
  "mux",
  opts = {
    workspaces = {
      root = wezterm.home_dir .. "/Workspaces",
      -- zoxide_path = "/custom/bin/zoxide",
    },
    hosts = {
      -- tailscale = false, -- disable optional Tailscale discovery
      -- tailscale_path = "/custom/bin/tailscale",
      -- known_hosts_files = { wezterm.home_dir .. "/.ssh/known_hosts" },
    },
  },
}
```

`workspaces` and `hosts` options are passed to their dedicated helpers. Remove
obsolete `quick_domains` options from personal overrides if present; they are no
longer consumed. No personal override files are modified automatically.
The helpers try executable names on PATH and conventional GUI PATH fallbacks;
explicit executable paths are authoritative rather than silently replaced.
Tailscale discovery requires `/usr/bin/perl` to enforce its deadline on any
platform where this helper is used. If Perl or Tailscale is unavailable, static
SSH sources remain usable. No package is installed automatically. Zoxide is
optional for the scan and active-workspace sources.

Workspace directory discovery currently handles POSIX absolute and `~/` paths;
Windows path support is not implemented. Raycast is macOS-only, and macOS is the
validated GUI platform. Linux GUI behavior needs separate acceptance testing.

## Module structure

Keep the flat feature-module architecture:

```text
wezmacs/modules/mux/
  init.lua        options, pane/switcher bindings, startup focus and status
  workspaces.lua  workspace sources, selection and previous-workspace history
  hosts.lua       SSH sources, current-tailnet freshness and native launch
```

The old workspace plugin's unquoted shell construction is replaced by direct
argv calls in the local helper. The mux module has no external plugin dependency
and no workspace mailbox or per-status filesystem polling.
One active-workspace status handler replaces the duplicated plugin callbacks;
status no longer assumes custom theme colors exist. No core loader/keycompiler
refactor, top-level module migration, SSH settings edit, tailnet manager or
agent integration is part of this change.

## Validation and manual acceptance

Automated regressions use real helper logic with narrow native window/process
boundaries stubbed. They cover source order/depth, literal paths, deduplication,
missing sources, selection/cancellation, previous-workspace history, endpoint
validation, tailnet changes, safe argv and binding integration. Run:

```sh
just check
WEZMACSDIR="$PWD/test" just smoke
WEZMACSDIR="$HOME/.config/wezmacs" just smoke
```

A headless native config check validates embedded Lua and native actions, not
actual key routing, GUI focus, authentication or network reachability. The local
verification additionally exercises actual filesystem/zoxide/SSH/Tailscale
source collection without selecting a host. No real tailnet switch or SSH
connection is performed by the automated checks.

Manual acceptance, in order:

1. Reload with Cmd-r. Open Leader-s and verify both a familiar zoxide path and a
   first-/second-level project you have not visited. Escape once: no workspace
   should be created.
2. Open a project. Confirm its cwd, switch elsewhere, then use Leader-S twice.
   Check that it toggles back and forth and the status follows the active
   workspace. Selecting an already open project should reuse that workspace.
3. Open Leader-d. Verify the tailnet, host names and online/offline labels, then
   Escape. Select an intended **personal** host only when ready to authenticate;
   expect a separate native SSH window. Do not use employer systems for agent
   validation.
4. After manually switching tailnets, reopen Leader-d: its tailnet-derived rows
   should be replaced, not merged with a cached prior network. If the picker was
   left open during the switch, selecting a stale peer should refuse and request
   reopening. Static SSH aliases/known-host entries remain intentionally static.
5. Check normal pane shortcuts still behave as before. The former advanced-domain
   shortcuts `D`, `|`, `_` are no longer supplied by this module.

## References

- [WezTerm workspace action](https://wezterm.org/config/lua/keyassignment/SwitchToWorkspace.html)
- [Native SSH command](https://wezterm.org/cli/ssh.html)
- [SSH configuration enumeration](https://wezterm.org/config/lua/wezterm/enumerate_ssh_hosts.html)
- [SSH domains and plain-vs-mux configuration](https://wezterm.org/config/lua/SshDomain.html)
- [Domain reload limitation](https://github.com/wezterm/wezterm/issues/7072)
- [Tailscale status structure](https://github.com/tailscale/tailscale/blob/main/ipn/ipnstate/ipnstate.go)
