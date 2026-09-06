#!/usr/bin/env bash
# Validate with WezTerm's embedded Lua and native API, never open a window.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
export WEZMACSDIR="${WEZMACSDIR:-$root/tests/fixtures/smoke}"
output="$(mktemp -d)"
trap 'rm -rf "$output"' EXIT
failed=false
# /dev/stdin keeps this test harness independent of WezTerm's config directory.
if ! printf '%s\n' "$(<"$root/scripts/smoke.lua")" | WEZMACS_SMOKE_ROOT="$root" WEZTERM_LOG=info wezterm --config-file /dev/stdin show-keys --lua > "$output/stdout" 2> "$output/stderr"; then
    failed=true
fi
# Exit 0 and the Lua completion log alone do not prove final native conversion.
success=false
native=false
while IFS= read -r line; do
    case "$line" in
        *"action = act.SendString '__WEZMACS_NATIVE_VALIDATED__'"*) native=true ;;
    esac
done < "$output/stdout"
while IFS= read -r line; do
    case "$line" in
        *'[WezMacs] Configuration loaded successfully'*) success=true ;;
    esac
    case "$line" in
        *' ERROR '*|*'[WezMacs] Module Error'*|*'[WezMacs] Error executing'*|*'[WezMacs] Failed to load'*|*'[WezMacs] modules.lua not found'*|*'[WezMacs] modules.lua must'*) failed=true ;;
    esac
done < "$output/stderr"
if [[ "$success" != true || "$native" != true || "$failed" == true ]]; then
    while IFS= read -r line; do printf '%s\n' "$line"; done < "$output/stdout"
    while IFS= read -r line; do printf '%s\n' "$line" >&2; done < "$output/stderr"
    printf '%s\n' 'WezTerm smoke validation failed.' >&2
    exit 1
fi
printf 'PASS native WezTerm config: %s\n' "$WEZMACSDIR"
