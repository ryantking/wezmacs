---
description: Astra reviews evidence and requests a native OpenSpec CLI archive
agent: astra
---
Read docs/agent-workflow.md. This explicit request authorizes consideration of
archiving change $ARGUMENTS, not bypassing verification. Select an existing
unambiguous local change. Read its proposal, design, specs, tasks, handoff and
verification. Confirm required checks have actual passing evidence against the
current candidate; stop on unresolved tasks, stale evidence or unverified required
GUI/network acceptance. Do not turn pending tasks into done merely to archive.

Run openspec validate <change-name> --strict --no-interactive and inspect the
proposed delta-to-main-spec updates, including substantive Purpose text for each
new capability (the CLI otherwise inserts a placeholder that strict validation
rejects). Explain the intended synchronization and
archive target before execution. Use the supported native CLI operation:

openspec archive <change-name> --yes --json

Request the normal bash-tool approval for that exact command. Keep validation and
spec synchronization enabled: do not add --no-validate or --skip-specs. Do not
follow the generated archive workflow's mkdir/mv steps; general filesystem shell
commands remain denied. Do not delegate filesystem operations to evade that deny.
If CLI archive fails, stop and report it; do not fall back to ad-hoc moves.

Read back the CLI-reported archive directory, verify the original active change
is absent using openspec list --json, inspect resulting main specs, and run
openspec validate --all --strict --no-interactive. Report exact results and
remaining risks. No commit, push, publication or runtime application.
