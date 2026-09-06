#!/usr/bin/env bash
# Select Lua 5.4 without relinking the user's global Lua.
set -euo pipefail
if [[ -n "${LUA:-}" ]]; then
    candidates=("$LUA")
else
    candidates=(lua5.4 lua54 /opt/homebrew/opt/lua@5.4/bin/lua /usr/local/opt/lua@5.4/bin/lua lua)
fi
for candidate in "${candidates[@]}"; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -e 'assert(_VERSION == "Lua 5.4")' >/dev/null 2>&1; then
        exec "$candidate" "$@"
    fi
done
printf '%s\n' 'Lua 5.4 required (WezTerm runtime). Install lua@5.4 or set LUA to its executable.' >&2
exit 1
