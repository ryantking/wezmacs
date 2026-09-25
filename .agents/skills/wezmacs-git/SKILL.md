---
name: wezmacs-git
description: Use when changing native Git comparisons, local checkout detection, worktree discovery, Delta or direnv launchers.
compatibility: OpenCode and other agents supporting repository-local skills
---

# Git discovery and launch safety

Read docs/git.md and modules/git/{init,repository,actions,launch,runtime}.lua.
Load wezmacs-validation. Keep WezTerm as the terminal surface, Git as repository
owner and Lazygit as interactive Git client, not a new orchestration framework.

- Scope is discovery/switching only. No creation, pruning, relocation, branch
  checkout, fetch, agent startup or hooks without separate requirements. Discover
  linked/detached trees via `git worktree list --porcelain -z`, not directory scans
  or fixed provider roots. A linked .git is a gitfile, not necessarily a directory.
- Query only verified local-domain/local-host OSC7 CWDs; a local ssh process can
  advertise a remote hostname. Never fall back to WezTerm's own CWD. Recheck local
  identity, common Git directory, current registrations and destination at accept.
- Reuse path-based workspaces; keep agent-owned worktree lifecycles untouched.
  Discovery is per repository, not across all clones or independent GUI muxes.
- Resolve revisions to full commit IDs. Working-tree-versus-ref, HEAD-versus-ref
  and merge-base-to-HEAD are distinct. Do not silently fall back to main/master.
  Picker labels are not command text; use safe argv and explicit manual entry.
- Apply local-only Git protections to metadata AND generated diff commands:
  --no-lazy-fetch, no optional locks, disabled fsmonitor and diff.autoRefreshIndex.
  --no-optional-locks alone does not prevent index changes from CRLF normalization.
- --no-ext-diff/--no-textconv do not disable clean/process filters or submodule
  helpers. Enumerate filter driver names, not secret config values; disable filter
  commands with required=true and fail closed if normalization needs one. Do not
  show unfiltered content as a correct diff. Preserve builtin CRLF handling and
  harmless unused LFS config. Compare submodules as gitlinks only, not dirty nested
  trees. Positive-control sentinels plus administrative-file hashes catch mutations.
- Delta reads patches on stdin: `delta <patch-file>` positional use may succeed
  without rendering. Regress installed Delta, explicit --pager, Git/pager exits,
  empty/error views and Enter-before-close. Inert stubs alone are insufficient.
- Native action.SplitPane uses size={Percent=integer} or Cells, directions Up/Down;
  pane:split accepts fractions. Do not copy one API's shape into the other.
- Interactive shells permit normal direnv prompt hooks; -lc alone does not imply
  direnv activation. Explicit direnv exec retains authorization. Never auto-allow
  .envrc, copy .direnv caches or execute environment files just to discover paths.
- Ordinary absolute Git administrative links are safest for Nix/libgit2 until
  tested. Relative destination paths are not extensions.relativeWorktrees.
  Do not repair Git metadata or switch to path: flakes automatically (different
  source filtering). Worktrees include committed files, not ignored local setup.

Tests: git_test.lua, git_actions_test.lua, git_native.lua, git_integration.sh,
git_safety.sh and their fixtures. Real temporary Git repositories, filter/promisor
sentinels and installed Delta are part of verification. Headless checks do not
prove interactive Lazygit rendering, pane focus or Nix environment activation.
