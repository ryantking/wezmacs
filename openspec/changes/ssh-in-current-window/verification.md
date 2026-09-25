# Verification: ssh-in-current-window

## Candidate and verifier
- Candidate: scoped runtime/test/docs edits in `wezmacs/modules/mux/hosts.lua`, `wezmacs/modules/mux/init.lua`, `tests/hosts_test.lua`, `tests/mux_test.lua`, new `tests/hosts_native.lua`, `docs/switchers.md`, `README.md`, and `FRAMEWORK.md`.
- Coder verification covered tasks 1.1, 2.1, 2.2 and 2.3. Independent task 3.1 was rerun after repair and passed.
- Initial status showed no tracked diff. Final status reports seven modified tracked runtime/test/documentation files, new scoped native test, and unrelated pre-existing untracked workflow/spec paths: `.agents/`, `.opencode/`, `docs/agent-workflow.md`, `opencode.json`, `openspec/`.
- All commands below ran from `/Users/ryan/.config/wezterm`.

## Red-green evidence

Before runtime edits, the new regressions were run against the original implementation:

| Command | Exit | Failure evidence |
| --- | ---: | --- |
| `bash scripts/lua.sh tests/hosts_test.lua` | 1 | New OpenSSH placement assertion expected two recorded actions and observed one; original code still used background native SSH. |
| `bash scripts/lua.sh tests/mux_test.lua` | 1 | `Leader+d must use the split placement`; original mux binding supplied no placement and no `D` binding. |

After implementation and formatting/lint repairs:

| Command | Exit | Result / evidence |
| --- | ---: | --- |
| `bash scripts/lua.sh tests/hosts_test.lua` | 0 | 28 Lua 5.4 tests passed, including alias/raw planner, freshness, cancellation, local guards, placement and action failure. |
| `bash scripts/lua.sh tests/mux_test.lua` | 0 | Split/tab binding routing and unrelated mux behavior passed. |
| `bash scripts/lua.sh tests/raycast_bridge_test.lua` | 0 | 4 bridge tests passed; native `wezterm ssh` argv contract remained unchanged. |
| `bash scripts/native-regressions.sh` | 0 | Appearance, Git, new SSH, and workspace harnesses passed; each reported strict conversion and rendered sentinel. `hosts_native.lua` reported `PASS native SSH actions`. |
| `just check` | 0 | StyLua, LuaLS with no diagnostics, all regression/tooling/Git/native/smoke checks passed. |
| `git diff --no-ext-diff --no-textconv --check` | 0 | No whitespace errors in tracked diff. |

## Independent tester evidence
- Added `tests/hosts_test.lua` coverage for Tailscale transport-vs-destination authentication semantics, unknown picker IDs, and an unreadable pane domain.
- Added `tests/hosts_native.lua` coverage for an unknown selection callback; the native harness still forbids process launches and requires strict conversion plus the rendered sentinel.

| Command | Exit | Independent result |
| --- | ---: | --- |
| `bash scripts/lua.sh tests/hosts_test.lua` | 1 | **FAIL** at `tests/hosts_test.lua:413`: expected the short Tailscale destination `desktop` but got `desktop.alpha.ts.net`. |
| `bash scripts/lua.sh tests/mux_test.lua` | 0 | Split/tab bindings and unrelated mux behavior passed. |
| `bash scripts/lua.sh tests/raycast_bridge_test.lua` | 0 | Native Raycast bridge tests passed. |
| `bash scripts/native-regressions.sh` | 0 | Appearance, Git, SSH and workspace native harnesses passed; SSH reported strict conversion and rendered sentinel. |
| `just check` | 1 | StyLua and LuaLS completed with no diagnostics; the test recipe stopped on the same SSH assertion. |
| `git diff --no-ext-diff --no-textconv --check` | 0 | No whitespace errors. |

### Blocking finding
Historical pre-repair finding: `wezmacs/modules/mux/hosts.lua:345-347` replaced the parsed Tailscale host with the verified FQDN, then `:386-399` also used that transport host as the OpenSSH destination. For a short peer such as `desktop`, this prevented OpenSSH `Host desktop` rules from supplying the intended `User`/identity authentication settings, even though `HostName=desktop.alpha.ts.net` was correctly pinned. The existing native plan deliberately kept `desktop` as its destination (`hosts.lua:371-374`), and the change's switcher contract requires short-name authentication semantics while pinning full transport identity. No production code was changed by the tester; task 3.1 was then left unchecked pending coder repair and rerun.

## Coder repair after independent finding
- Production change was limited to `wezmacs/modules/mux/hosts.lua`: validated selections now retain the logical destination host/user separately while Tailscale freshness still replaces only the transport host used by `HostName=`. Native `launch_args()` remains on its prior path and semantics.
- Two focused existing assertions in `tests/hosts_test.lua` were updated because they still expected the pre-finding FQDN destination for Tailscale rows; the tester's short-destination regression at line 413 was preserved.
- No docs, Raycast source, scripts, personal settings or unrelated paths were changed.

| Command | Exit | Repair result |
| --- | ---: | --- |
| `bash scripts/lua.sh tests/hosts_test.lua` | 0 | 30 Lua 5.4 tests passed, including short Tailscale destination plus unknown/unreadable-domain coverage. |
| `bash scripts/lua.sh tests/mux_test.lua` | 0 | Split/tab routing passed. |
| `bash scripts/lua.sh tests/raycast_bridge_test.lua` | 0 | Native Raycast bridge compatibility passed. |
| `bash scripts/native-regressions.sh` | 0 | All native harnesses passed with strict conversion and rendered sentinels. |
| `just check` | 0 | Formatting, LuaLS, all regression/tooling/Git/native/smoke checks passed. |
| `git diff --no-ext-diff --no-textconv --check` | 0 | No whitespace errors. |

The focused short-destination regression was retained through repair; task 3.1 is now independently verified.

## Independent rerun after repair
- The repair was inspected against the actual diff: logical destination host/user is captured before Tailscale transport freshness rewrites `parsed.host`; native `launch_args()` and the native harness contract remain unchanged.
- The short-destination regression at `tests/hosts_test.lua:413` was retained. Existing assertions were updated only where they still encoded the pre-repair FQDN destination, not weakened or removed.

| Command | Exit | Independent result |
| --- | ---: | --- |
| `bash scripts/lua.sh tests/hosts_test.lua` | 0 | 30 Lua 5.4 tests passed, including short Tailscale destination, unknown selection and unreadable-domain coverage. |
| `bash scripts/lua.sh tests/mux_test.lua` | 0 | Split/tab routing and unrelated mux behavior passed. |
| `bash scripts/lua.sh tests/raycast_bridge_test.lua` | 0 | Native Raycast bridge compatibility passed. |
| `bash scripts/native-regressions.sh` | 0 | All native harnesses passed with strict conversion and rendered sentinels; SSH harness reported `PASS native SSH actions`. |
| `just check` | 0 | Formatting, LuaLS, all regression/tooling/Git/native/smoke checks passed. |
| `git diff --no-ext-diff --no-textconv --check` | 0 | No whitespace errors. |

## Acceptance mapping
- Default `leader d` split and `leader D` tab routing: `tests/mux_test.lua`, `tests/hosts_test.lua`, `tests/hosts_native.lua` passed in the targeted/native checks.
- Direct OpenSSH argv: `hosts.openssh_args()` and placement callback assertions; raw rows include `HostName`, `-p` including 22, `ProxyCommand=none`, `ProxyJump=none`, `--`, and validated destination.
- Native/Raycast compatibility: existing `hosts.launch_args()` assertions and `tests/raycast_bridge_test.lua` passed unchanged in semantics.
- Local-origin opening/submission checks: unit and native callback tests; remote panes produce notifications without discovery or placement.
- Fresh discovery, cancellation, invalid/stale rows, literal aliases, unknown rows, domain errors, synchronous action failures and short Tailscale destinations: independently passed after repair.
- Native process/network safety: native harness stubs `run_child_process` and `background_child_process` to fail; no process or network launch occurred.

## Documentation task 4.1
- `docs/switchers.md` now documents `leader d` as a Right/50% current-tab split and `leader D` as a current-window tab, local-origin checks, direct system OpenSSH semantics, logical-vs-transport Tailscale identity, freshness, and the retained IPv6 limitation. The native-new-window rationale is explicitly scoped to Raycast SSH.
- `README.md` now reflects both bindings, local-only OpenSSH placement, normal OpenSSH config/authentication, raw transport pinning, and Raycast's independent native window behavior.
- `FRAMEWORK.md` now records the mux action boundary, local-pane requirement, alias/raw semantics, freshness, IPv6 limitation, and the separate Raycast native window path.
- No runtime or test files were changed for task 4.1.

| Command | Exit | Documentation result |
| --- | ---: | --- |
| `just check` | 0 | Formatting, LuaLS, regression, native, smoke and integration checks passed after documentation edits. |
| `git diff --no-ext-diff --no-textconv --check` | 0 | No whitespace errors. |

## Boundaries and remaining work
- GUI rendering, actual focus, OpenSSH authentication, remote connectivity and interactive key routing: NOT RUN; require separately authorized disposable acceptance and remain task 5.1.
- Documentation task 4.1, independent verification task 3.1, and final review task 4.2 are complete. GUI/network task 5.1 remains BLOCKED on separate authorization. No Raycast source was changed.
- No dependencies, personal settings, commits, pushes, publishes or archives were performed.

## Final tester review: task 4.2 portion
- Current tracked diff contains exactly the seven intended implementation/test/documentation paths: `wezmacs/modules/mux/hosts.lua`, `wezmacs/modules/mux/init.lua`, `tests/hosts_test.lua`, `tests/mux_test.lua`, `docs/switchers.md`, `README.md`, and `FRAMEWORK.md`.
- Intended untracked scope was also inspected: `tests/hosts_native.lua` plus the active change artifacts including `tasks.md`, `verification.md`, and `handoff.md`. Pre-existing unrelated untracked `.agents/`, `.opencode/`, `docs/agent-workflow.md`, `opencode.json`, and other OpenSpec scaffolding remain untouched.
- `git diff --stat --no-ext-diff --no-textconv` reports 7 files changed, 378 insertions and 142 deletions; the untracked native harness and change artifacts are not included in that statistic. Compared with the passing task 4.2 review, only the intended README wording changed; runtime and test diff counts remain unchanged.
- Documentation matches verified split/tab placement, local-domain checks, direct OpenSSH versus Raycast native SSH, logical-vs-transport Tailscale identity, freshness, proxy/port behavior, and the IPv6 limitation.
- Resolved precision finding: `README.md:114-116` now says Raycast shares discovery and selection validation with terminal pickers but uses transport-specific launch planning; typed fallbacks and distinct transports remain documented.

| Command | Exit | Final tester result |
| --- | ---: | --- |
| `just check` | 0 | Formatting, LuaLS, all regression/tooling/Git/native/smoke checks passed after documentation edits. |
| `git diff --no-ext-diff --no-textconv --check` | 0 | No whitespace errors. |

## Final reviewer precision correction
- README-only wording correction; no runtime or test files changed.
- Corrected text now says Raycast shares Lua discovery and selection validation with terminal pickers but uses transport-specific launch planning, preserving the distinct native Raycast and terminal OpenSSH transports.

| Command | Exit | Final correction result |
| --- | ---: | --- |
| `just check` | 0 | Formatting, LuaLS, all regression/tooling/Git/native/smoke checks passed on the final candidate. |
| `git diff --no-ext-diff --no-textconv --check` | 0 | No whitespace errors. |

The independent final tester rerun is complete.

## Planner final review

- Reviewed actual runtime and repair diffs, documentation diffs, relevant regression/native harness contents, and independent verification evidence. Runtime ownership remained limited to the two approved mux files; Raycast source and personal settings were unchanged.
- The independent tester found and the coder repaired one logical-destination/authentication regression. The tester retained the failing regression and independently verified the fix; no unresolved offline behavior failures remain.
- `openspec validate ssh-in-current-window --strict --no-interactive` ran from the repository root and exited **0**, reporting the change valid. This is structural evidence only, separate from the tester's `just check` exit **0**.
- Task 4.2 is complete. Overall tasks: **7/8 complete**. Task 5.1 remains unchecked and **BLOCKED** on separate disposable GUI/personal-host authorization. No GUI placement, focus, actual authentication, or live Raycast window acceptance is claimed.
