#!/usr/bin/env bash
# Real local Git + embedded Lua regression. No GUI, user hooks, or network.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
fixture="$(cd "$fixture" && pwd -P)"
trap 'rm -rf "$fixture"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS GIT_CONFIG GIT_CEILING_DIRECTORIES
export WEZMACS_SMOKE_ROOT="$root" WEZMACSDIR="$root/tests/fixtures/smoke"
export WEZMACS_GIT_FIXTURE="$fixture"
export WEZMACS_GIT_REPO="$fixture/repo with ' quote [x]; literal"
export WEZMACS_GIT_LINKED="$fixture/agent-owned/feature checkout"
export WEZMACS_GIT_DETACHED="$fixture/agent-owned/$(printf 'detached\ncheckout')"
export WEZMACS_GIT_MISSING="$fixture/removed-checkout"
export WEZMACS_GIT_REPLACED="$fixture/replaced-checkout"
mkdir -p "$WEZMACS_GIT_REPO/subdir" "$fixture/agent-owned"
git init -q -b main "$WEZMACS_GIT_REPO"
git -C "$WEZMACS_GIT_REPO" config user.name 'WezMacs fixture'
git -C "$WEZMACS_GIT_REPO" config user.email 'fixture@example.invalid'
git -C "$WEZMACS_GIT_REPO" config commit.gpgsign false
git -C "$WEZMACS_GIT_REPO" config core.hooksPath /dev/null
printf '%s\n' '#!/bin/sh' 'touch "$WEZMACS_GIT_FIXTURE/external-diff-executed"' > "$fixture/external-diff"
chmod +x "$fixture/external-diff"
git -C "$WEZMACS_GIT_REPO" config diff.external "$fixture/external-diff"
git -C "$WEZMACS_GIT_REPO" config diff.wezmacs_fixture.textconv "$fixture/external-diff"
git -C "$WEZMACS_GIT_REPO" config delta.pager "$fixture/external-diff"
printf '%s\n' 'tracked.txt diff=wezmacs_fixture' > "$WEZMACS_GIT_REPO/.gitattributes"
printf '%s\n' base > "$WEZMACS_GIT_REPO/tracked.txt"
# Never execute a repository environment merely to discover Git information.
printf '%s\n' 'touch "$WEZMACS_GIT_FIXTURE/envrc-executed"' > "$WEZMACS_GIT_REPO/.envrc"
git -C "$WEZMACS_GIT_REPO" add tracked.txt .envrc .gitattributes
git -C "$WEZMACS_GIT_REPO" commit -qm base
export WEZMACS_GIT_BASE="$(git -C "$WEZMACS_GIT_REPO" rev-parse HEAD)"
git -C "$WEZMACS_GIT_REPO" -c tag.gpgsign=false tag -a v1 -m base
# A tag that does not peel to a commit must not become a usable comparison.
blob="$(git -C "$WEZMACS_GIT_REPO" rev-parse HEAD:tracked.txt)"
git -C "$WEZMACS_GIT_REPO" -c tag.gpgsign=false tag blob-tag "$blob"
printf '%s\n' main > "$WEZMACS_GIT_REPO/main.txt"
git -C "$WEZMACS_GIT_REPO" add main.txt
git -C "$WEZMACS_GIT_REPO" commit -qm main
export WEZMACS_GIT_MAIN="$(git -C "$WEZMACS_GIT_REPO" rev-parse HEAD)"
git -C "$WEZMACS_GIT_REPO" worktree add -q --no-relative-paths -b 'feature/literal$ref' "$WEZMACS_GIT_LINKED" "$WEZMACS_GIT_BASE"
printf '%s\n' feature > "$WEZMACS_GIT_LINKED/feature.txt"
git -C "$WEZMACS_GIT_LINKED" add feature.txt
git -C "$WEZMACS_GIT_LINKED" commit -qm feature
export WEZMACS_GIT_FEATURE="$(git -C "$WEZMACS_GIT_LINKED" rev-parse HEAD)"
printf '%s\n' dirty >> "$WEZMACS_GIT_LINKED/tracked.txt"
git -C "$WEZMACS_GIT_REPO" worktree add -q --no-relative-paths --detach "$WEZMACS_GIT_DETACHED" "$WEZMACS_GIT_BASE"
git -C "$WEZMACS_GIT_REPO" worktree lock --reason 'agent-owned fixture' "$WEZMACS_GIT_DETACHED"
git -C "$WEZMACS_GIT_REPO" worktree add -q --no-relative-paths --detach "$WEZMACS_GIT_MISSING" "$WEZMACS_GIT_BASE"
rm -rf "$WEZMACS_GIT_MISSING"
git -C "$WEZMACS_GIT_REPO" worktree add -q --no-relative-paths --detach "$WEZMACS_GIT_REPLACED" "$WEZMACS_GIT_BASE"
rm -rf "$WEZMACS_GIT_REPLACED"
git init -q -b foreign "$WEZMACS_GIT_REPLACED"
git -C "$WEZMACS_GIT_REPLACED" -c user.name=Fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit --allow-empty -qm foreign
git -C "$WEZMACS_GIT_REPO" worktree list --porcelain -z > "$fixture/worktrees.before"
git -C "$WEZMACS_GIT_LINKED" status --porcelain=v1 -z > "$fixture/status.before"
# Exercise generated launch commands only against inert executables. Isolate
# login-shell HOME and diff scratch files; never source personal shell settings.
export HOME="$fixture/home" TMPDIR="$fixture/tmp/"
export LESS= LESSOPEN= LESSCLOSE= DELTA_FEATURES=
if delta_binary="$(command -v delta)"; then
    export WEZMACS_GIT_REAL_DELTA="$delta_binary"
else
    unset WEZMACS_GIT_REAL_DELTA
fi
export WEZMACS_GIT_STUBS="$fixture/tools ' literal"
mkdir -p "$HOME" "$TMPDIR" "$WEZMACS_GIT_STUBS"
printf '%s\n' '#!/bin/sh' \
    'if [ "${1-}" = --version ]; then printf "fixture-tool\\n"; exit 0; fi' \
    'printf "<cwd>%s</cwd>\\n" "$PWD"' \
    'for arg do printf "<arg>%s</arg>\\n" "$arg"; done' \
    'exit "${WEZMACS_GIT_TOOL_EXIT:-0}"' > "$WEZMACS_GIT_STUBS/tool"
printf '%s\n' '#!/bin/sh' \
    'if [ "${1-}" = --version ]; then printf "fixture-direnv\\n"; exit 0; fi' \
    'test "$1" = exec || exit 67' 'shift' 'target=$1' 'shift' \
    'cd "$target" || exit 68' 'printf "<direnv>%s</direnv>\\n" "$PWD"' \
    'exec "$@"' > "$WEZMACS_GIT_STUBS/direnv"
printf '%s\n' '#!/bin/sh' \
    'if [ "${1-}" = --version ]; then printf "fixture-delta\\n"; exit 0; fi' \
    'test "$1" = --paging && test "$2" = always || exit 69' 'shift 2' \
    'if [ "$#" -gt 0 ]; then test "$#" = 2 && test "$1" = --pager && test "$2" = "less -R" || exit 69; fi' \
    'printf "<delta>\\n"' \
    'while IFS= read -r line; do printf "%s\\n" "$line"; done' > "$WEZMACS_GIT_STUBS/delta"
chmod +x "$WEZMACS_GIT_STUBS/tool" "$WEZMACS_GIT_STUBS/direnv" "$WEZMACS_GIT_STUBS/delta"
cd "$root"
failed=false
if ! WEZTERM_LOG=info wezterm --config-file /dev/stdin show-keys --lua < tests/git_fixture.lua > "$fixture/stdout" 2> "$fixture/stderr"; then
    failed=true
fi
success=false
sentinel=false
while IFS= read -r line; do
    case "$line" in
        *'PASS real Git fixture'*) success=true ;;
        *' ERROR '*) failed=true ;;
    esac
done < "$fixture/stderr"
while IFS= read -r line; do
    case "$line" in
        *"action = act.SendString '__WEZMACS_GIT_FIXTURE_VALIDATED__'"*) sentinel=true ;;
    esac
done < "$fixture/stdout"
if [[ "$failed" == true || "$success" != true || "$sentinel" != true ]]; then
    while IFS= read -r line; do printf '%s\n' "$line" >&2; done < "$fixture/stderr"
    printf 'FAIL real Git fixture (success=%s, sentinel=%s)\n' "$success" "$sentinel" >&2
    exit 1
fi
git -C "$WEZMACS_GIT_REPO" worktree list --porcelain -z > "$fixture/worktrees.after"
git -C "$WEZMACS_GIT_LINKED" status --porcelain=v1 -z > "$fixture/status.after"
cmp "$fixture/worktrees.before" "$fixture/worktrees.after"
cmp "$fixture/status.before" "$fixture/status.after"
test ! -e "$fixture/envrc-executed"
test ! -e "$fixture/external-diff-executed"
test ! -e "$fixture/injected"
printf '%s\n' 'PASS real Git fixture (linked/detached checkouts, literal paths, launch argv/direnv/diff status, no repository mutation)'
if [[ -n "${WEZMACS_GIT_REAL_DELTA:-}" ]]; then
    printf '%s\n' 'PASS installed Delta rendering and configured-pager bypass (noninteractive)'
fi
