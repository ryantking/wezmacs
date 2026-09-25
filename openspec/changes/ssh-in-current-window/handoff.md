# Handoff: ssh-in-current-window

## Scope and current request
- User requested internal SSH split/tab placement and approved system OpenSSH with a right-hand 50% split; Raycast remains native SSH in a new window. See `proposal.md` for scope and exclusions.
- Explicit apply authorization covered implementation and offline verification. Tasks 1.1 through 4.2 are complete; only separately authorized interactive acceptance task 5.1 remains blocked.
- Worktree: repository root. Exact current status has modified `FRAMEWORK.md`, `README.md`, `docs/switchers.md`, `tests/hosts_test.lua`, `tests/mux_test.lua`, `wezmacs/modules/mux/hosts.lua`, and `wezmacs/modules/mux/init.lua`; new scoped `tests/hosts_native.lua`; active change artifacts under `openspec/changes/ssh-in-current-window/`; and unrelated untracked `.agents/`, `.opencode/`, `docs/agent-workflow.md`, `opencode.json`, and other OpenSpec scaffolding. No tracked baseline diff existed before implementation. Preserve all unrelated paths. No commit/publish/archive authorization.
- Separate GUI/network acceptance remains unauthorized and unperformed.

## Current work
- Task IDs and ownership are defined in `tasks.md`; the scoped coder implementation is complete.
- Tasks 1.1, 2.1, 2.2 and 2.3 are implemented and were verified by the coding worker. Independent task 3.1 found a real destination/authentication regression; the scoped coder repair was independently rerun and now passes. Task 3.1 is complete.
- Active writing worker: none. Implementation, independent verification, documentation, and planner final review are complete.

## Decisions and failures
- Separate OpenSSH planning from native `hosts.launch_args()`; preserve native/Raycast behavior. Use Right/50% split and same-window tab native actions. See `design.md`.
- Proposed local-origin guard follows existing Git launch conventions; OpenSSH sessions launched by this feature remain local-domain panes. Already attached native remote-domain panes are outside scope.
- Retain literal aliases; pin raw hostname and port, disable both OpenSSH proxy mechanisms; preserve identity freshness checks and current IPv6 restriction.
- Red regressions against the original implementation exited hosts 1 and mux 1. The coder's post-edit `just check` first exposed formatting, then LuaLS duplicate-field warnings in the native harness; both were fixed in scope. The independent tester then found that OpenSSH reused the pinned FQDN as the logical destination, bypassing short `Host` authentication rules.
- Repair keeps separate logical destination host/user fields from freshly verified transport `HostName`; native `launch_args()` remains unchanged. Two focused existing assertions were updated to require the tester-approved short Tailscale destination, while the tester's regression remained intact. Independent rerun checks all exit 0. GUI placement/focus and actual SSH authentication/network acceptance remain unperformed and are not implied by headless evidence. Full evidence is in `verification.md`.

## Independent tester result
- Task 3.1 was executed after the coder stopped writing. Focused additions cover Tailscale short-destination authentication semantics, unknown picker IDs, unreadable domains, and native unknown-selection callbacks.
- Historical pre-repair result: `hosts_test.lua` failed at line 413 because OpenSSH planning emitted `desktop.alpha.ts.net` instead of the short `desktop` destination needed for matching OpenSSH `Host desktop` authentication rules. This was repaired in `wezmacs/modules/mux/hosts.lua:330-355,380-402`; the tester did not patch production.
- Pre-repair exact checks: hosts test 1 (expected blocking failure), mux test 0, Raycast bridge 0, native regressions 0, `just check` 1 (same assertion after clean format/LuaLS), diff check 0. See `verification.md` for evidence.
- Task 3.1 is complete after the independent rerun. Documentation task 4.1 and final review task 4.2 are also complete; GUI/network task 5.1 remains blocked.

## Final tester review result
- Reviewed the complete final tracked diff, untracked `tests/hosts_native.lua`, and active task/evidence artifacts. The seven tracked changed paths are the intended runtime, test, and documentation paths; unrelated untracked workflow files remain preserved.
- `just check` exited 0 and `git diff --no-ext-diff --no-textconv --check` exited 0 after task 4.1 documentation edits.
- Documentation is consistent with verified behavior. The final reviewer precision finding in `README.md:114-116` was corrected to describe shared discovery/selection validation with transport-specific launch planning; typed fallbacks and distinct transports remain documented.
- The correction was README-only; runtime and test paths are unchanged from the passing task 4.2 review. Final `just check` and whitespace checks both exited 0.
- Planner reviewed the runtime/repair/documentation diffs, relevant test contents, and independent command evidence. `openspec validate ssh-in-current-window --strict --no-interactive` exited 0; this proves artifact structure only. Task 4.2 is complete. Task 5.1 remains blocked without GUI/network authorization.

## Resume
- Next safe action: report the implemented bindings and passing offline checks. Await explicit authorization and an appropriate disposable personal test environment for GUI/network task 5.1; do not archive this change while required interactive acceptance remains unresolved.
- Verification evidence: `verification.md`.
