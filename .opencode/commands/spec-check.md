---
description: Astra delegates independent implementation-versus-spec verification to Luna
agent: astra
---
Read AGENTS.md and docs/agent-workflow.md. Select the existing change $ARGUMENTS.
Load openspec-verify-change and wezmacs-validation. Delegate independent verification
to tester with the change artifacts, candidate diff, relevant skills and required
checks. The tester must run real checks, map requirements/scenarios to evidence,
and distinguish GUI/network checks from headless tests. Use sol for hard diagnosis
only. Record PASS/FAIL/BLOCKED and exact commands in verification.md, then review
that evidence. Do not silently fix production code, archive or publish.
