# WezMacs contributor notes

- Read `FRAMEWORK.md` for the implemented module/keybinding contracts.
- Runtime: WezTerm embedded Lua 5.4. Use `bash scripts/lua.sh`, not an arbitrary system Lua.
- `just check`: read-only format check, LuaLS diagnostics, regression tests and native smoke.
- `just fmt` explicitly writes formatting; `just demo` explicitly opens a GUI.
- `just types` installs pinned editor-only annotations. Never add `.lua-libs/` to runtime `package.path`.
- Add a failing regression before changing framework behavior. Use real code and a minimal native-API stub where unavoidable.
- Use an isolated worktree for larger changes; preserve personal overrides in `~/.config/wezmacs`.
- Preserve unrelated shortcuts/appearance; do not launch agents or type into an existing pane as a test.
- No automatic commits, worktree manager, repository MCP setup or agent hooks. Use ordinary Git when requested.
- Keep secrets and transient research out of the repository. Document GUI tests separately from headless checks.
