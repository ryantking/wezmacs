# WezMacs development and local validation. Check recipes never reformat files.
set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := false

types_rev := "e40662a318c89284402f7f18e6e447b1c7fc1476"
types_dir := ".lua-libs/wezterm-types"
lua_sources := "wezterm.lua wezmacs scripts test tests types"

default:
    @just --list

# Explicit development setup; no runtime Lua packages and no global Lua relink.
deps:
    brew install lua@5.4 stylua lua-language-server just
    just types

# Fetch a pinned annotation-only library; never put it on runtime package.path.
types:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -d "{{types_dir}}/.git" ]]; then
        git clone --depth 1 https://github.com/DrKJeff16/wezterm-types.git "{{types_dir}}"
    fi
    if [[ -n "$(git -C "{{types_dir}}" status --porcelain)" ]]; then
        printf '%s\n' 'Type library has local changes; refusing to overwrite.' >&2
        exit 1
    fi
    git -C "{{types_dir}}" fetch --depth 1 origin "{{types_rev}}"
    git -C "{{types_dir}}" checkout --detach "{{types_rev}}"

# Intentional formatting is separate from validation.
fmt:
    stylua {{lua_sources}}

fmt-check:
    stylua --check {{lua_sources}}

# LuaLS is both editor LSP and headless diagnostic checker.
lint:
    @test -d "{{types_dir}}/lua" || { printf '%s\n' 'Run just types first.' >&2; exit 1; }
    lua-language-server --check=. --configpath=.luarc.json --checklevel=Warning --logpath=.cache/luals --metapath="{{justfile_directory()}}/.cache/luals/meta"

# Pure Lua regressions plus native smoke checker failure-path coverage.
test:
    @for file in tests/*_test.lua; do bash scripts/lua.sh "$file"; done
    bash tests/tooling_test.sh

# Offline core fixture; WEZMACSDIR may select another config for plugin coverage.
smoke:
    bash scripts/smoke.sh

check: fmt-check lint test smoke

# Generate configuration; refuses to overwrite either existing user file.
init:
    bash scripts/lua.sh scripts/generate-config.lua

# Explicitly interactive; never part of tests/check.
demo:
    WEZMACSDIR="$PWD/test" wezterm --config-file "$PWD/wezterm.lua" start --always-new-process

# Installation is cloning this repository; no self-delete/update automation.
status:
    @git status --short
    @wezterm --version
    @bash scripts/lua.sh -v
    @stylua --version
    @lua-language-server --version
