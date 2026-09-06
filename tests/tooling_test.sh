#!/usr/bin/env bash
# Exercise the smoke wrapper's fail-closed behavior without opening a GUI.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
bash scripts/lua.sh -e 'assert(_VERSION == "Lua 5.4")'
if LUA=/usr/bin/false bash scripts/lua.sh -v >/dev/null 2>&1; then
    printf '%s\n' 'FAIL accepted invalid LUA override' >&2
    exit 1
fi
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
printf '%s\n' 'error("intentional smoke regression")' > "$fixture/modules.lua"
printf '%s\n' 'return {}' > "$fixture/config.lua"
if WEZMACSDIR="$fixture" bash scripts/smoke.sh > "$fixture/output" 2>&1; then
    printf '%s\n' 'FAIL smoke accepted a broken configuration' >&2
    exit 1
fi
# A valid Lua module can still assign an invalid native configuration field.
printf '%s\n' 'return {{ "term", setup = function(config) config.__wezmacs_invalid_option = true end }}' > "$fixture/modules.lua"
if WEZMACSDIR="$fixture" bash scripts/smoke.sh > "$fixture/output" 2>&1; then
    printf '%s\n' 'FAIL smoke accepted an invalid native configuration field' >&2
    exit 1
fi
# Mutations inside an already-assigned table bypass config-builder assignment checks.
printf '%s\n' 'return {{ "term", setup = function(c) c.keys = {}; table.insert(c.keys, { key = "F23", mods = "NOTAMOD", action = require("wezterm").action.SendString("nested") }) end }}' > "$fixture/modules.lua"
if WEZMACSDIR="$fixture" bash scripts/smoke.sh > "$fixture/output" 2>&1; then
    printf '%s\n' 'FAIL smoke accepted invalid nested modifiers' >&2
    exit 1
fi
printf '%s\n' 'PASS smoke rejects invalid nested modifiers'
# ERROR is valid action data, not a log severity.
printf '%s\n' 'return {{ "term", setup = function(c) c.keys = {{ key = "F23", mods = "CTRL", action = require("wezterm").action.SendString("ERROR") }} end }}' > "$fixture/modules.lua"
if ! WEZMACSDIR="$fixture" bash scripts/smoke.sh > "$fixture/output" 2>&1; then
    printf '%s\n' 'FAIL smoke rejected valid SendString("ERROR")' >&2
    exit 1
fi
printf '%s\n' 'PASS smoke accepts valid SendString("ERROR")'
# Also require a positive case; absence of the wrapper cannot make this test pass.
bash scripts/smoke.sh
printf '%s\n' 'PASS Lua selection and smoke reject invalid configuration'
