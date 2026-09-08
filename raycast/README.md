# Wezterm for Raycast

A local Raycast extension bundled with WezMacs. The bundle is named **Wezterm**
and uses the official WezTerm icon; see [asset attribution](assets/ATTRIBUTION.md).
It adds exactly two commands, without assigning hotkeys or installing a daemon.

## Commands

### Open Workspace

Search the current WezTerm workspace names, ranked zoxide directories, and the
first two directory levels beneath `~/Workspaces`. Every accepted selection opens
a **new independent WezTerm GUI window**, even when that workspace already exists.
Existing windows are unchanged. This starts a fresh local shell in the selected
directory; it does not clone tabs, panes, running programs, or pane layouts.

For a directory absent from discovery, type an absolute path or `~/` path and
choose its explicit fallback action. The directory must already exist; this
command does not create directories. Spaces and Unicode in paths are literal,
not shell syntax. A file path is rejected.

Path-based workspace names resolve directly to existing local directories.
Opaque names use a fresh `wezterm cli --no-auto-start list --format json` lookup
and an existing local `file://` pane directory (empty host, localhost, or this
machine's hostname). Remote-host directories are never reused as local paths.
If no local directory is available, choose an explicit existing folder instead.
Inventory is whichever GUI the CLI currently addresses, not an aggregate of all
independent GUIs; path fallback remains available during discovery.

Launch is shell-free macOS LaunchServices:
`/usr/bin/open -n -a <verified app path> --env WEZMACS_RAYCAST_NEW_WINDOW=1 --args start --always-new-process --no-auto-connect --domain local --workspace <name> --cwd <directory>`.
The explicit environment marker opts the new local GUI into WezMacs' startup
focus handler; ordinary local startup behavior is not changed.
The selected executable must belong to a valid WezTerm app bundle; its real path
determines the app, including custom installations and executable symlinks. No
other installation is silently substituted. Success means LaunchServices accepted
the launch, not that GUI rendering or shell startup was independently confirmed.

The optional `path` command argument initializes the search. It does not launch
anything without accepting an action in the list.

### SSH to Host

Search configured SSH aliases, readable `~/.ssh/known_hosts`, and devices in the
currently active Tailscale account. Discovery happens when the command opens;
selecting a listed Tailscale device revalidates its identity and address before
planning the launch. Tailscale failure does not remove static SSH choices.

For a different username or unlisted address, type a target and select the
explicit manual action. Supported examples:

```text
my-ssh-alias
alice@my-ssh-alias
alice@192.0.2.44
alice@192.0.2.44:2222
alice@host.example
```

These are examples, not configured hosts. The optional `target` command argument
prefills the search and never auto-connects. No passwords, SSH option strings, or
remote commands are accepted. Authentication stays in native WezTerm.

Configured aliases preserve their SSH configuration, including deliberate proxy
routes. A typed username/port can override an alias's defaults. Raw destinations
explicitly constrain HostName, port, and ProxyCommand to preserve the selected
direct destination. Native SSH opens a separate WezTerm window on the validated
`c7f4b081` build; no remote WezTerm installation is required.

**IPv6 limitation:** this installed native CLI has an unsafe literal-address
parser. Use an SSH-config alias for an IPv6 destination rather than a typed IPv6
literal. Hashed known-host names cannot be enumerated.

## Install on a Mac

Requirements:

- Raycast for macOS, signed in if its development/import workflow requires it.
- A WezTerm macOS app bundle and this WezMacs checkout for discovery.
- A Node/npm installation compatible with the pinned Raycast API; the package
  lock controls dependency versions.
- zoxide and Tailscale are optional discovery sources.

From this directory:

```sh
npm ci
npm test
npm run typecheck
npm run format:check
npm run build
npm run dev
```

`build` uses `ray build -e dist -o dist`: `-e` selects the distribution environment,
and **`-o` explicitly confines generated files to ignored `dist/`**. Omitting the
output flag writes to Raycast's extension directory even without registering the
commands. The validation build does not import the extension. **`dev` builds/imports
it into Raycast and can bring Raycast to the front.** Stop the development watcher after it reports readiness; the
commands remain installed. Run it again after pulling source changes to update
the local installation. No publishing is required or performed by these steps.

Find **Open Workspace** or **SSH to Host** in Raycast. Configure global hotkeys
or aliases through Raycast yourself; the extension does not claim any shortcuts.

### Preferences

- **WezMacs Repository:** defaults to `~/.config/wezterm`; change this if your
  checkout is elsewhere.
- **WezTerm Executable:** optional absolute CLI override. Otherwise the extension
  checks the app bundle and standard installation locations. Open Workspace needs
  `WezTerm.app/Contents/MacOS/wezterm` (or a symlink resolving there); a standalone
  CLI is rejected with a preference error rather than opening a different app.

Each Mac reads its own directories, SSH config, and active tailnet. Do not copy
host inventories or authentication data between machines as part of installation.
Raycast Cloud Sync is not the deployment path for this local source: sync the Git
checkout, install dependencies, and import on each Mac.

## Implementation and trust boundary

- `src/` provides the Raycast lists and a bounded, shell-free native bridge client.
- `../scripts/raycast.lua` runs inside headless native WezTerm. It loads only the
  workspace/host helpers, returns a JSON envelope, and includes a native sentinel
  so config fallback cannot masquerade as success. It never launches SSH itself.
- Discovery uses the shared helpers' defaults. This headless process deliberately
  does not execute personal `modules.lua`, `config.lua`, or third-party plugins.
  Future custom discovery overrides need an explicit bridge configuration rather
  than arbitrary personal config execution.
- `../wezmacs/modules/mux/hosts.lua` owns input validation, stale-peer checks, and
  native SSH argument planning for both launchers.
- `src/workspace.ts` launches independent app windows and validates local CWDs.
- Code running as your own macOS user is inside the trust boundary, as it already
  controls your terminal configuration. This is not a remote API or sandbox.

## Verification and manual acceptance

Run `just check` at the repository root and the Node checks above. Automated
checks must not make remote connections or type into terminal panes.

Manual acceptance after installation:

1. Open each Raycast command and cancel it; no terminal should be spawned.
2. Open a directory not in the discovered list using the explicit path fallback.
3. Select an existing workspace twice; verify two new independent windows open
   in its local directory and existing windows/pane layouts remain unchanged.
   Try an opaque workspace with only remote CWDs; it must reject with a folder hint.
4. In SSH to Host, inspect the active tailnet label and select an intended host.
   Confirm the username and authenticate yourself.
5. Test a typed `user@host` or IP target. Invalid options or a nonexistent
   directory should produce an error, not execute arbitrary text.
6. After switching tailnets yourself, reopen SSH to Host and confirm the peer
   list changes. A selection from an older tailnet must be rejected.

Actual authentication and cross-machine deployment require separate user testing;
a successful build is not a claim that either was exercised.
