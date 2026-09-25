# Spec Delta

## Purpose

Provide SSH access in the current terminal window through predictable split/tab shortcuts, while preserving safe host selection and Raycast's independent-window behavior.

## ADDED Requirements

### Requirement: Default SSH placement shortcuts

The terminal SHALL bind `leader d` to the SSH picker with right-hand 50% split placement and `leader D` to the same picker with new-tab placement. Accepted launches SHALL run system OpenSSH in the current window, without launching a new GUI window or replacing an existing pane's process. Unrelated default shortcuts and user key overrides MUST remain intact.

#### Scenario: Split selection
- **WHEN** the user invokes default `leader d` from a local pane and selects a valid host
- **THEN** an OpenSSH session is launched in a new right-hand 50% split of the current tab
- **AND** no independent window is requested

#### Scenario: Tab selection
- **WHEN** the user invokes default `leader D` from a local pane and selects a valid host
- **THEN** an OpenSSH session is launched in a new tab of the current window
- **AND** the existing tab and its pane processes remain intact

### Requirement: Local launch boundary

Internal SSH launches SHALL require an originating pane in the local domain and SHALL recheck this boundary on submission. A non-local or unverifiable domain SHALL result in no SSH process, split, or tab creation and an explanatory notification. The implementation MUST NOT execute the SSH client through a remote pane's domain.

#### Scenario: Remote domain invocation
- **WHEN** either internal SSH shortcut is invoked from a non-local domain
- **THEN** the picker does not open and a notification explains the local-pane requirement
- **AND** no discovery or process launch is attempted

#### Scenario: Domain changes before submission
- **WHEN** a previously opened picker is submitted but the callback pane is no longer verifiably local
- **THEN** no split, tab, or SSH process is created and the user is notified

### Requirement: Fresh and cancellable host selection

Both placements SHALL retain the same host sources and opening-time discovery as the existing picker, with no discovery during configuration evaluation and no connection probes. The prompt SHALL retain `SSH hosts: ` including its trailing space. Cancellation MUST do nothing. Optional discovery failure SHALL retain available static choices without reusing stale peer snapshots.

#### Scenario: Fresh opening
- **WHEN** either picker is opened again after the available hosts change
- **THEN** choices are collected for that opening rather than reused from configuration evaluation or an older opening

#### Scenario: Cancel selection
- **WHEN** the user cancels either picker
- **THEN** no launch, split, tab, or cancellation-error notification occurs

#### Scenario: Optional discovery unavailable
- **WHEN** optional peer discovery fails while static host choices are available
- **THEN** those static choices remain selectable and old peer snapshots are not substituted

### Requirement: Literal aliases and pinned raw endpoints

Internal SSH launch arguments SHALL be passed directly without shell interpolation. Configured SSH aliases SHALL be preserved literally as destinations and retain deliberate OpenSSH user, port, proxy, and identity configuration. Raw discovered endpoints SHALL explicitly pin the validated transport hostname and port, including port 22, and disable both proxy-command and proxy-jump redirection while retaining applicable authentication settings. No launch SHALL modify SSH configuration.

#### Scenario: Configured alias
- **WHEN** the selected row is a valid configured SSH alias
- **THEN** OpenSSH receives that exact alias as its destination
- **AND** deliberate alias-specific proxy, user, identity, and port settings are not overridden by raw-endpoint safety options

#### Scenario: Raw endpoint with conflicting SSH configuration
- **WHEN** a valid raw endpoint is selected and matching SSH configuration would redirect its hostname, port, or proxy route
- **THEN** the launch explicitly specifies the selected transport hostname and port and disables both proxy mechanisms
- **AND** the destination is not passed as an OpenSSH `host:port` shorthand

#### Scenario: Invalid or unsupported destination
- **WHEN** selection data contains an invalid host, option-like destination, invalid port, or a currently unsupported literal IPv6 endpoint
- **THEN** no SSH process or placement action is requested and the user receives an error notification

### Requirement: Submission identity validation

Submission SHALL retain existing serialized-selection validation and Tailscale tailnet/self identity, peer ID, and address freshness checks before planning an OpenSSH launch. A failed validation SHALL notify the user without fallback to an unvalidated destination.

#### Scenario: Stale peer selection
- **WHEN** a selected peer disappears or its required identity/address no longer matches the opening-time selection
- **THEN** no split, tab, SSH connection, or independent window is requested and the user is notified

#### Scenario: Invalid selection payload
- **WHEN** the submitted row cannot be validated as an available supported selection
- **THEN** no launch occurs and the user is notified

### Requirement: Native window compatibility

Raycast SSH SHALL retain its existing validated native `wezterm ssh` launch plan and independent-window behavior. The internal placement change MUST NOT alter the headless bridge contract, native raw-endpoint options, Raycast focus handling, or Raycast source.

#### Scenario: Raycast launch plan remains native
- **WHEN** the headless bridge plans a valid Raycast SSH selection
- **THEN** it returns the same native WezTerm SSH argv semantics as before this change
- **AND** no terminal split/tab action is substituted

### Requirement: Accurate failure and acceptance reporting

Internal launches SHALL NOT silently fall back to a separate window on validation or launch failure. Documentation SHALL distinguish OpenSSH configuration/authentication from native WezTerm SSH and SHALL distinguish headless placement-plan evidence from actual GUI placement and network authentication evidence.

#### Scenario: Launch action fails synchronously
- **WHEN** the native placement action reports an immediate failure
- **THEN** an actionable error is reported without an alternate window launch

#### Scenario: Headless validation only
- **WHEN** regression and native headless checks pass but no authorized interactive session has been exercised
- **THEN** the verification record marks actual GUI placement and SSH authentication as not run or blocked rather than passed
