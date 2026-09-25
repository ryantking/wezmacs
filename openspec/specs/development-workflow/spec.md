# Development workflow

## Purpose

Preserve WezMacs contributor knowledge and verifiable change handoffs across
independent coding-agent sessions without adding runtime agent infrastructure.

## Requirements

### Requirement: Repository-local engineering guidance
The repository SHALL provide portable skills for core architecture, native
validation, appearance, workspace/SSH discovery, Git safety and Raycast boundaries.

#### Scenario: Fresh agent starts work
- **WHEN** an agent begins a WezMacs change without earlier conversation history
- **THEN** the repository workflow guide identifies the applicable repository-local skills and architecture references
- **AND** those files do not require access to a maintainer's private memory directory

### Requirement: Specification and implementation role separation
The configured OpenCode workflow SHALL keep Astra in planning/orchestration,
with scoped implementation and independent testing delegated to worker roles.

#### Scenario: User requests a proposal
- **WHEN** a proposal command runs
- **THEN** it produces planning artifacts and stops for review without application-code changes

#### Scenario: User authorizes implementation
- **WHEN** the user subsequently requests implementation of an agreed change
- **THEN** the orchestrator dispatches scoped coding work followed by independent verification
- **AND** at most one writing worker operates in a shared worktree at a time

### Requirement: Durable evidence and continuity
An in-progress change SHALL retain tasks, decisions, failures, verification
evidence and the next safe action in repository-local artifacts when work pauses.

#### Scenario: Work resumes in a new session
- **WHEN** an agent resumes an existing change
- **THEN** it reads the change artifacts and reconciles the handoff with current Git state
- **AND** unresolved checks remain explicitly unverified rather than being assumed passed

### Requirement: Native validation cannot rely on exit zero alone
Contributors MUST retain native strict conversion, completion markers and rendered
sentinel checks alongside Lua regressions for applicable WezTerm behavior changes.

#### Scenario: Native configuration silently falls back
- **WHEN** a native check exits zero but the expected rendered sentinel is absent
- **THEN** the supervising check reports failure

#### Scenario: A change requires GUI acceptance
- **WHEN** headless checks pass but required GUI or network behavior has not been exercised
- **THEN** the verification report distinguishes that gap and does not claim full acceptance

### Requirement: No unrequested runtime or external changes
Contributor setup SHALL NOT install runtime agent hooks, mutate personal terminal
configuration, import Raycast extensions, connect to hosts or publish changes.

#### Scenario: Agent validates source changes
- **WHEN** an agent performs contributor checks
- **THEN** generated build artifacts remain confined to ignored development paths
- **AND** installation, publication and personal configuration changes require separate authorization
