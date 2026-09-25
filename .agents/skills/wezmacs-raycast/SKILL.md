---
name: wezmacs-raycast
description: Use when changing the optional Raycast TypeScript extension, headless WezTerm bridge or independent-window launch.
compatibility: OpenCode and other agents supporting repository-local skills
---

# Raycast integration: build without installation

Read raycast/README.md, raycast/package.json, scripts/raycast.lua and
raycast/src/{backend,workspace,ui}.ts plus command components. Load
wezmacs-validation and wezmacs-mux-ssh. Raycast settings, shortcuts, import and
deployment are outside source-validation scope and require explicit approval.

## Commands

Run from raycast/: `npm test`, `npm run typecheck`, `npm run format:check`,
`npm run build`; run `just check` at root. Inspect scripts first. Build must keep
`ray build -e dist -o dist`: -e alone can still write into installed extensions.
Do not run npm run dev as validation (it imports and foregrounds Raycast).
Use npm ci only when dependencies need installation, preserving package-lock.

## Architecture and lifecycle

- The bridge evaluates native headless Lua with only shared workspace/host
  helpers and defaults; no personal config or plugins. Require its JSON envelope
  AND rendered sentinel. Bridge planning must not itself launch SSH.
- Shared inventory uses native `cli --no-auto-start list --format json` argv and
  parsing. A cold GUI may mean empty discovery; malformed data is an error.
  Opaque workspace acceptance re-queries and requires a fresh existing local
  file:// CWD (validated hostname). No silent home fallback.
- Running/folder partitioning is memoized by discovery, not search query.
  Preserve opaque IDs/order. Explicit path fallback does not wait for inventory.
- Every accepted workspace opens a NEW independent local GUI/fresh shell, not a
  switch/clone of existing panes. Inventory belongs only to the addressed GUI,
  not all independent processes. Discovery and prefilled arguments never launch.
- Resolve and verify the executable's actual app bundle (including symlinks).
  Shell-free LaunchServices uses open -n, its explicit startup marker and native
  start --always-new-process --no-auto-connect --domain local with literal cwd
  and workspace. A standalone binary must not silently select another install.
- Keep the one-shot update-status focus deferral for tagged local launches; avoid
  enumerating mux windows during local gui-attached (native window-lock deadlock).
  SSH startup follows its separate focus path. No daemon, mailbox, status polling
  or provider-owned session management is required.
- Static aliases retain their settings; raw/manual destinations use the shared
  validated SSH planner. Tailscale rows are refreshed/rechecked. No credentials,
  remote commands or SSH option strings accepted as user target input.

Tests live in raycast/tests and tests/raycast_bridge_test.lua. Mocked rendering,
source compilation and LaunchServices acceptance do not prove GUI focus/auth.
Check exact PID/frontmost state only in approved disposable sessions; do not
unlock a Mac when loginwindow is frontmost. POSIX path discovery and macOS-only
Raycast do not constitute Windows/Linux GUI support.

Keep generated dist/node_modules/types out of Git. Never deploy scratch dependency
symlinks as source or assume node_modules/ ignores a symlink named node_modules.
