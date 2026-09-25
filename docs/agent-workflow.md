# Spec-driven development and session continuity

OpenSpec is contributor tooling, not part of WezMacs runtime. Specifications and
engineering lessons live in this repository so a fresh agent can orient without
access to a previous chat or a maintainer's private Hermes skills.

## Start a session

1. Read AGENTS.md, FRAMEWORK.md and CONTRIBUTING.md, then Git status/diff including
   untracked files. Do not overwrite user changes or start audit-debt work unasked.
2. Load `wezmacs-core` and `wezmacs-validation` from `.agents/skills/`, then the
   relevant `wezmacs-appearance`, `wezmacs-mux-ssh`, `wezmacs-git` or
   `wezmacs-raycast`. If your tool has no skill loader, read those SKILL.md files.
3. Run `openspec list --json` to discover active changes. Read the chosen change's
   proposal.md, design.md, specs/, tasks.md, handoff.md and verification.md where
   present. Resolve conflicting/current state against disk, not chat recollection.
4. Check `openspec status --change <name> --json` and retrieve current instructions
   before editing artifacts. Missing handoff/evidence is unknown, not a pass.

`openspec/specs/` holds maintained requirements. `openspec/changes/<name>/specs/`
holds deltas; a change is not the maintained baseline until synchronized. Existing
FRAMEWORK.md and feature guides remain architecture references; do not rewrite
the entire brownfield application into specs before doing useful work. The
initial development-workflow spec records the contributor contract only.

## Installed OpenCode workflow

Launch `opencode` from the checkout root. This machine's global agent definitions
supply Astra high, Luna xhigh coder/tester, Luna medium explore and Sol xhigh. Repo
`opencode.json` supplies local skill permissions, instructions and narrowly scoped
planner access; it does not connect accounts, add MCP servers or install hooks.
On another machine, configure equivalent agents or use your own tool's roles;
the reusable WezMacs skills and OpenSpec artifacts are model-independent.

| Command | Result |
| --- | --- |
| `/spec <idea>` | Select Astra explicitly; create proposal/spec/design/tasks and stop for review. |
| `/implement <change-name>` | Select Astra explicitly; dispatch scoped Luna coding, then independent Luna testing; persist evidence. |
| `/spec-check <change-name>` | Select Astra explicitly; delegate independent spec-versus-implementation checks to tester. |
| `/resume-change <change-name>` | Select Astra explicitly; reconstruct state from disk and report next safe action without implementing. |
| `/spec-archive <change-name>` | Select Astra explicitly; review evidence and request CLI archive/synchronization approval. |

The standard generated `/opsx-propose`, `/opsx-explore`, `/opsx-apply`,
`/opsx-update`, `/opsx-sync`, `/opsx-archive`, `/opsx-verify` are also available.
They run under the currently selected OpenCode agent; keep Astra selected to
preserve this workflow. Prefer the wrappers above for explicit agent selection.
For archive use `/spec-archive <change-name>` after verification. The generated
`/opsx-archive` uses generic mkdir/mv shell instructions that the restricted
planner cannot execute. The custom wrapper instead invokes the supported
`openspec archive <change-name> --yes --json` with normal tool approval, then
reads back the archive and main specs. It keeps validation/spec sync enabled.
No general shell grants, generated-file edits or auto-archive are needed.

Native config enforces model/variant routing in the globally configured roles and
planner tool restrictions; sequencing, handoff completeness, independence and
escalation remain prompt-directed, not a deterministic pipeline or sandbox.
Generated skills cannot grant extra permissions. Astra may edit change Markdown
and maintained spec Markdown only, not application code, tests, scripts or agent
policy; bounded OpenSpec scaffolding is allowed, archive asks. Workers have their
own edit/test authority. Direct build/plan mode is an explicit alternate workflow.
Git shell commands for Astra and explore require approval: broad diff/log/show
arguments can write with --output or execute configured helpers, so they are not
a read-only sandbox. Review exact arguments; never approve a write to circumvent
planner restrictions. Use native file inspection when shell approval is unavailable.

## Work and verification contract

Astra owns design/acceptance and delegates implementation. Every worker receives:

- change directory and exact task IDs;
- goal, owned files and excluded scope;
- relevant skill names/paths and applicable instructions;
- requirements/scenarios and exact verification commands;
- current Git state and prior failure evidence.

One writing worker per worktree, sequential coder then independent tester. Native
subagent contexts are separate but their filesystem is shared. Parallel work needs
separately provisioned worktrees and an integration decision; this setup does not
create or manage them automatically. Sol is a deliberate escalation for hard
failures or after two unsuccessful Luna repairs, never an auth/quota failover.

Proposal is planning-only, even if the idea says "build". Wait for a new explicit
apply/implement request before coding. Do not add unapproved scope, weaken tests,
change private configs, commit, push, publish, import Raycast or connect to a host.

`openspec status` checks artifact existence; `openspec validate` checks artifact
structure. Neither proves behavior. Record exact commands/exits and map scenarios
to actual test evidence. For GUI changes, list unperformed visual/focus/network
checks as BLOCKED or NOT RUN rather than implying headless tests covered them.
Do not archive with unresolved required checks, even if the CLI allows it.

## Durable handoff

Use the templates in `.agents/templates/` to maintain these additional files
inside the active change (they are not extra schema dependencies):

- `handoff.md`: approved scope, state, task IDs/ownership, decisions, failed
  approaches, blockers and next safe action.
- `verification.md`: tested revision/diff state, exact commands and exits,
  requirement/scenario evidence, independent verifier, unperformed checks.

Update on pause, worker return and before ending a session. Keep raw logs in
ignored `.cache/` where useful; the durable report needs enough compact evidence
to remain useful after logs disappear. Never store credentials, private host
inventories, employer data or machine-specific personal configuration here.
Task progress belongs in tasks.md; do not maintain a conflicting second checklist.

For stable new lessons, update the relevant `.agents/skills/wezmacs-*/SKILL.md`
with a procedure and why it matters, not a session transcript. Amend architecture
or feature docs when behavior changes; update the active spec delta separately.

## Install and refresh

OpenSpec setup was generated with CLI 1.13.1; Node >=20.19 is required. Install
that reproducible version with `npm install -g @fission-ai/openspec@1.13.1`, or
review a newer version before upgrading. Then use these preferences to regenerate
this integration (these settings are GLOBAL OpenSpec preferences):

```sh
OPENSPEC_TELEMETRY=0 openspec config set telemetry.enabled false
openspec config set profile custom
openspec config set delivery both
openspec config set workflows '["propose","explore","apply","update","sync","archive","verify"]'
openspec init --tools opencode --profile custom --no-animation
```

For an initialized checkout, use `openspec update` after a reviewed CLI upgrade.
Generated `.opencode/skills/openspec-*` and `.opencode/commands/opsx-*` belong to
OpenSpec: do not customize them. Keep policy in AGENTS.md, opencode.json,
.opencode/instructions.md and openspec/config.yaml, and wrappers in separate files.
The custom `wezmacs-*` skills use the shared `.agents` root; no additional plugin
or Hermes-home link is required. Other harnesses may read them directly.

Useful non-model diagnostics:

```sh
openspec list --json
openspec validate --all --strict --no-interactive
opencode debug config
opencode debug skill
opencode debug agent astra
opencode debug agent coder
opencode debug agent tester
opencode debug agent sol
```

Inspect diagnostics locally; resolved config can include private global prompts
or provider data, so do not commit raw output. Verify expected skills are not
merely discovered but permitted for each agent. Restart OpenCode after changing
configuration. No live model prompt is required to validate discovery; actual
account/model entitlement and delegation require a separate post-login smoke test.
