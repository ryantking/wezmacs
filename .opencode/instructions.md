# WezMacs agent workflow

Read AGENTS.md and docs/agent-workflow.md at session start and after compaction.
Load wezmacs-core and wezmacs-validation plus the skill for the changed subsystem.
Use repository-local OpenSpec changes for durable requirements, design, tasks,
handoffs and verification; chat history is not the source of truth.

For the user's native OpenCode agents: Astra specifies/orchestrates; coder (Luna
xhigh) implements; tester (Luna xhigh) verifies independently; sol (Sol xhigh)
handles hard failures or two unsuccessful Luna repair attempts. Never substitute
paid routes after authentication, quota or unavailable-model errors.

Astra can edit planning Markdown under openspec/ only, not production code,
tests, scripts, agent policy or this file. It may run bounded OpenSpec commands.
Generated OpenSpec apply/verify instructions describe the outcome, not a change
in role: Astra must use coder/tester to do implementation and execute tests.
No generic shell, shell redirection or worker delegation to circumvent a denied
planner edit. Spec-directory permissions are guardrails, not an OS sandbox.

Planning commands stop for review. An explicit subsequent apply/implement request
is authorization to execute the agreed scope, not to publish or alter runtime
personal settings. Require a new decision on material scope changes. Use one
writing worker at a time. A worker receives its change path, exact task IDs,
owned paths, relevant skill names, acceptance criteria, check commands and prior
failure evidence; do not assume workers inherit conversation context.

For cross-session continuation read changes/<name>/handoff.md, tasks.md,
verification.md and current Git status/diff; verify each claim against disk and
actual test results. Do not resume an old task just because it is mentioned in
a handoff when the current user request changes direction. If no active change
exists, propose only the requested feature; do not pick an audit item yourself.

Never confuse `openspec status` (artifact existence), checked task boxes, or
`openspec validate` (artifact structure) with behavior verification. Archive only
on explicit request, after required checks pass and spec sync is reviewed. Use
/spec-archive and its approval-gated native openspec archive command rather than
the generated mkdir/mv steps. Do not widen general shell permission to archive.
Astra/explore Git shell calls require approval because --output and configured
helpers can write or execute code; inspect exact arguments and never use them
to bypass planner edit restrictions.
