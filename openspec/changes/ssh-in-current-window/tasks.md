# Tasks

## 1. Failing regressions

- [x] 1.1 Coder owns `tests/hosts_test.lua` and `tests/mux_test.lua`: add regressions for default `d` split / `D` tab routing, direct OpenSSH argv, unchanged native argv, literal aliases, pinned raw host/port and both disabled proxies, local-domain checks at opening/submission, cancellation, discovery freshness, invalid/stale selections, and synchronous action failure. Verify the new behavior fails against the original implementation with `bash scripts/lua.sh tests/hosts_test.lua` and `bash scripts/lua.sh tests/mux_test.lua`; record exact exits and failure assertions before runtime edits.

## 2. Implementation and native coverage

- [x] 2.1 Coder owns `wezmacs/modules/mux/hosts.lua`: add a separate OpenSSH launch planner with minimum shared selection validation, preserving native `launch_args()` semantics. Verify alias/raw endpoint and freshness tests pass with `bash scripts/lua.sh tests/hosts_test.lua` and Raycast compatibility with `bash scripts/lua.sh tests/raycast_bridge_test.lua`.
- [x] 2.2 Coder owns `wezmacs/modules/mux/hosts.lua` and `wezmacs/modules/mux/init.lua`: implement local-only picker placement with a Right/50% split default and explicit tab variant; bind `leader d` and `leader D`, retaining cancellation and notification conventions and forbidding background/new-window fallback. Verify both targeted suites pass with `bash scripts/lua.sh tests/hosts_test.lua` and `bash scripts/lua.sh tests/mux_test.lua`.
- [x] 2.3 Coder owns new `tests/hosts_native.lua`: cover real native action conversion and picker callbacks using narrow stubs, no processes/network, strict builders, protected-suite markers, and rendered sentinels. Verify with `bash scripts/native-regressions.sh`, then run `just check` and persist actual command exits and evidence in this change's `verification.md`.

## 3. Independent verification

- [x] 3.1 After the coder has stopped writing, tester owns verification and focused test additions in `tests/hosts_test.lua`, `tests/mux_test.lua`, and `tests/hosts_native.lua` only. Review the actual diff against every scenario, preserve native/Raycast argv and local-domain boundaries, and rerun `bash scripts/lua.sh tests/hosts_test.lua`, `bash scripts/lua.sh tests/mux_test.lua`, `bash scripts/lua.sh tests/raycast_bridge_test.lua`, `bash scripts/native-regressions.sh`, and `just check`. Record exact exits, native completion evidence, scenario coverage, and blockers in `verification.md`; passing worker summaries alone do not complete this task.

## 4. Documentation and final review

- [x] 4.1 After independent behavior verification, coder owns `docs/switchers.md`, affected shortcut references in `README.md`, and affected SSH contract references in `FRAMEWORK.md`: document split/tab defaults, the local-origin requirement, OpenSSH configuration semantics, and unchanged Raycast native windows. Verify by reviewing those references against implemented actions and running `just check` after documentation edits.
- [x] 4.2 After all writers finish, tester reviews the final candidate and reruns `just check`; planner reviews actual changed files and verification evidence, updates `handoff.md` and `verification.md`, and runs `openspec validate ssh-in-current-window --strict --no-interactive`. Verify only intended paths changed and distinguish structural validation from behavior checks.

## 5. Separately authorized interactive acceptance

- [ ] 5.1 Tester/user, only after explicit disposable GUI and personal-host connection authorization: exercise `leader d`, `leader D`, cancellation, remote-domain rejection, SSH authentication, and session exit without typing into an existing live pane. Observe Right/50% split vs new tab in the same window, preserved existing processes, and no extra SSH window; separately confirm Raycast still opens an independent native window. Record exact fixture ownership and observations in `verification.md`. Keep this task unchecked and report BLOCKED while authorization or an appropriate disposable environment is unavailable; headless checks cannot substitute for it.
