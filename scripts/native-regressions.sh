#!/usr/bin/env bash
# Embedded-runtime regressions; native exit 0 alone can hide config fallback.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
export WEZMACS_SMOKE_ROOT="$root"
export WEZMACSDIR="$root/tests/fixtures/smoke"
output="$(mktemp -d)"
trap 'rm -rf "$output"' EXIT
cd "$root"
for harness in tests/*_native.lua; do
    failed=false
    if ! WEZTERM_LOG=info wezterm --config-file /dev/stdin show-keys --lua < "$harness" > "$output/stdout" 2> "$output/stderr"; then
        failed=true
    fi
    sentinel=false
    success=false
    while IFS= read -r line; do
        case "$line" in
            *"action = act.SendString '__WEZMACS_REGRESSION_VALIDATED__'"*) sentinel=true ;;
        esac
    done < "$output/stdout"
    while IFS= read -r line; do
        case "$line" in
            *'PASS native '*) success=true ;;
            *' ERROR '*) failed=true ;;
        esac
    done < "$output/stderr"
    if [[ "$failed" == true || "$sentinel" != true || "$success" != true ]]; then
        while IFS= read -r line; do printf '%s\n' "$line" >&2; done < "$output/stderr"
        printf 'FAIL native regression: %s (sentinel=%s, success=%s)\n' "$harness" "$sentinel" "$success" >&2
        exit 1
    fi
    printf 'PASS native regression: %s (strict conversion + rendered sentinel)\n' "$harness"
done
