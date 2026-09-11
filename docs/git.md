# Git launchers, comparisons, and worktrees

WezMacs provides terminal entry points, not a second Git client or an agent
manager. Lazygit owns interactive staging, commits, rebases and conflict handling;
Git owns repository and worktree discovery; WezTerm owns panes, tabs and workspaces.

## Keys

On the default macOS setup, press Cmd-Space, release, then `g` and the key below.

| Key | Action |
| --- | --- |
| `g` | Lazygit in a side pane |
| `G` | Lazygit in a new tab |
| `d` | Native comparison picker, diff in a side pane |
| `D` | Native comparison picker, diff in a new tab |
| `w` | Native worktree picker, open or reuse a workspace |
| `h` | GitHub dashboard in a side pane |
| `H` | GitHub dashboard in a new tab |

Launchers resolve the checkout from the active local pane, including subdirectories
and linked worktrees. They do not assume `.git` is a directory. Native local
queries must not interpret a remote pane's path as a local repository.

## Comparisons

Choose a branch, remote-tracking branch, tag, or recent commit using a native
fuzzy picker. Use the explicit revision-entry action for a commit or revision
outside the bounded list. Cancellation does not run a comparison.

Comparison modes are distinct:

- **Working tree against ref:** selected commit versus the current tracked files,
  including staged and unstaged changes. Untracked files are not in Git's diff.
- **HEAD against ref:** selected commit versus the current committed snapshot.
- **Branch changes since base:** merge-base of the selected ref and HEAD versus
  HEAD, like a typical pull-request comparison. This excludes uncommitted changes.

This replaces the old silent `main` / `master` / remote fallback chain. A missing
ref or invalid revision produces an error instead of comparing against another
branch. Revisions are resolved as commits before they are used as diff arguments;
choice labels are presentation, not shell commands.

Comparison commands require a Git version supporting `--no-lazy-fetch` and never
fetch missing partial-clone objects implicitly. Fetch needed objects separately
if Git reports they are unavailable locally.

Working-tree comparisons do not execute configured clean/process filters. If
Git needs such a filter to normalize tracked content, the comparison fails
rather than running it or presenting a misleading unfiltered diff. Unused
installed filters do not block ordinary repositories; committed comparisons
remain available. Submodules are shown as **gitlink commit changes only**:
nested dirty/untracked worktree contents and inline submodule patches are not
inspected. Open the submodule itself to compare its content.

Lazygit remains available for its in-app diff mode. The module does not invent a
Lazygit command-line flag for opening an arbitrary comparison, inject keystrokes,
or modify Lazygit's state/configuration to simulate that behavior.

## Worktrees

The picker uses `git worktree list --porcelain -z` for the current repository.
Every registered checkout can be found regardless of its path or creator. Agent
cache directories, sibling checkouts and nested `.worktrees` directories need no
special provider adapter. Detached worktrees are identified by path and commit,
not an assumed branch name.

Opening a worktree reuses its path-based WezTerm workspace when present, otherwise
opens a normal shell in a new workspace rooted at that checkout. Git discovery
is repository-wide, **not** a machine-wide search for independent clones or other
repositories. Workspace reuse is within the current WezTerm GUI client's mux
inventory, not a claim of cross-process window activation.

Creation, deletion, pruning, relocation, branch checkout, automatic fetching,
agent startup and setup hooks are deliberately outside this module's worktree
scope. Closing a terminal workspace does not delete its checkout. Agent-owned
worktrees retain their owning application's lifecycle; a checkout removed by its
owner must be rejected when a stale picker selection is submitted.

## Nix and direnv

Ordinary linked worktrees contain a `.git` **file** that points to Git metadata.
They are compatible with standard Git-aware tooling. `.git/worktrees` is Git's
administrative directory, not a place for working checkouts.

Nix/libgit2 support for Git's `extensions.relativeWorktrees` is version-dependent;
see the upstream compatibility issue below before enabling it. Ordinary linked
worktrees do not require that extension. A relative destination such as
`../feature` is not the same feature as `git worktree add --relative-paths`.
This module only discovers worktrees and does not change either setting or
attempt automatic metadata repair.

New workspaces start a normal interactive shell at the target path. With the
user's normal direnv hook installed, environment loading happens at its prompt.
An unapproved `.envrc` still requires the user to review and allow it. No launcher
runs `direnv allow`, copies secrets, shares `.direnv` caches, or evaluates a
repository's environment simply to populate a picker.

New checkouts contain files from their selected commit, not ignored/untracked
local setup from another checkout. Git-backed flakes also require new source
files to be added to Git before evaluation can see them. Switching to a `path:`
flake is not an equivalent compatibility fix: it changes source filtering.

## Options

Configure the module in your `modules.lua`, for example:

```lua
{ "git", opts = {
  split_direction = "Right",
  split_size = 0.5,
  comparison_mode = "working_tree",
  commit_limit = 50,
  direnv = "auto",
  broot = false,
  lazyjj = false,
} },
```

- `split_direction`: `Left`, `Right`, `Up`, or `Down`. Git splits default to
  the right, rather than changing direction with the window's aspect ratio.
- `split_size`: fraction from `0.01` to `0.99`, rounded to a whole percentage.
- `comparison_mode`: `working_tree`, `head`, or `merge_base`. This selects the
  first/default entry in the explicit mode picker, not an implicit branch fallback.
- `commit_limit`: integer from `0` to `500`; zero omits recent commits but retains
  branches, tags and manual revision entry. References are local; nothing fetches.
- `direnv`: `"auto"` wraps direct tools in `direnv exec <checkout>` when available;
  `true` requires direnv; `false` bypasses it. A blocked `.envrc` stays blocked.
  This controls direct tool launches, not the user's interactive shell hook.
- `broot = true` restores `s`/`S` status launchers; `lazyjj = true` restores `j`
  for a Git-backed/colocated Jujutsu checkout. Both are disabled by default.
- `git_path`, `lazygit_path`, `delta_path`, `direnv_path`, `gh_path`, `broot_path`,
  `lazyjj_path`: optional single executable paths, **not shell command strings**.
  Default lookup tries PATH and conventional macOS/local-bin locations.
- `shell`: optional executable override for the login-shell launcher; otherwise
  uses the framework's `config.shell`. Its command syntax must accept POSIX-style
  argument quoting. No global shell configuration is rewritten.

`h`/`H` require `gh` plus its `gh-dash` extension. Lazygit, Delta, GitHub dashboard
and optional TUIs must be installed separately; dependency metadata does not
install them. Missing required executables report an error when invoked.
The old `diff_branches` option is obsolete: select a revision and comparison
mode explicitly. Diffs use Delta with a controlled pager, then wait for Enter
before closing, including empty results and Git failures.

## Validation boundaries

`just check` includes native headless action/conversion checks and disposable
real-Git fixture tests. The real-Git fixture covers worktree gitfiles, detached
and locked trees, stale paths, shell metacharacters, and newline-containing paths.
It verifies discovery does not modify the repository or execute `.envrc`.

Headless tests are not a claim of visual picker rendering, real pane focus,
interactive Lazygit behavior, or successful loading of a project's Nix dev shell.
No existing terminal session is used as a test target.

## References

- [Git worktrees](https://git-scm.com/docs/git-worktree)
- [Git repository layout](https://git-scm.com/docs/gitrepository-layout)
- [WezTerm InputSelector](https://wezterm.org/config/lua/keyassignment/InputSelector.html)
- [Direnv hook and exec behavior](https://direnv.net/man/direnv.1.html)
- [Nix relative-worktree compatibility issue](https://github.com/NixOS/nix/issues/14987)
- [Lazygit diff renderers](https://github.com/jesseduffield/lazygit/blob/v0.64.1/docs/Custom_DiffRenderers.md)
