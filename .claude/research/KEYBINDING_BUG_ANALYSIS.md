# WezMacs Keybinding Bug: Root Cause Analysis and Solution

## Problem Summary

Keybindings are "shifting" or triggering incorrect actions. For example:
- `LEADER g g` should open lazygit but opens the Claude workspace selector instead
- Other keybindings randomly call different actions
- This occurs across multiple modules (git, claude, editors, domains)
- Issue affects both built-in and external keyboards

## Root Cause: Duplicate LEADER Keybindings

After analyzing the codebase, I've identified the critical bug:

**Multiple modules are registering the SAME keybinding (LEADER + different key letters) but the key table activation is conflicting because WezTerm uses first-match-wins for keybindings in the `config.keys` array.**

### The Problem in Detail

Each module creates its own key table and registers an activation keybinding:

```lua
-- git/init.lua (line 55-63)
table.insert(config.keys, {
  key = mod.leader_key,          -- "g"
  mods = mod.leader_mod,         -- "LEADER"
  action = act.ActivateKeyTable({ name = "git", ... })
})

-- claude/init.lua (line 54-62)
table.insert(config.keys, {
  key = mod.leader_key,          -- "c"
  mods = mod.leader_mod,         -- "LEADER"
  action = act.ActivateKeyTable({ name = "claude", ... })
})

-- editors/init.lua (line 41-56)
table.insert(config.keys, {
  key = mod.editor_split_key,    -- "e"
  mods = "LEADER",
  action = wezterm.action_callback(actions.terminal_smart_split)
})

-- domains/init.lua (line 37-56)
-- Uses quick_domains plugin which sets up its OWN keybindings
table.insert(config.keys, {
  key = mod.leader_key,          -- "t"
  mods = mod.leader_mod,         -- "LEADER"
  ...
})
```

**Key table modules affected:**
- `git` - LEADER + "g" → activate "git" key table
- `claude` - LEADER + "c" → activate "claude" key table
- `docker` - LEADER + "d" → activate "docker" key table
- `file-manager` - LEADER + "f" → activate "file-manager" key table
- `editors` - Direct LEADER + "e/E/i" bindings (NOT a key table)
- `domains` - LEADER + "t" → handled by quick_domains plugin (may set up additional keybindings)

## Why It's Manifesting as Wrong Actions

The issue likely occurs due to one or more of these scenarios:

### Scenario 1: Key Table Stack Interference (Most Likely)
When a key table is active and you press LEADER + another key, WezTerm:
1. Checks the active key table for a binding
2. Falls through to `config.keys` if not found in the key table

If the active key table has overlapping keys (e.g., "g" is in the git key table but you also press it while the claude key table is somehow still active), precedence issues occur.

### Scenario 2: Module Load Order Dependency
Modules load in an undefined order (they're iterated from a Lua table with `pairs()`). In Lua 5.1+, table iteration order for non-sequential keys is **non-deterministic**. This means:

- Sometimes `git` module loads before `claude`
- Sometimes `claude` loads before `git`
- The module that loads LAST will have its keybindings added LAST to `config.keys`
- WezTerm uses first-match in `config.keys` for the default keybinding lookup

This inconsistency could cause different behaviors on reload or between sessions.

### Scenario 3: Shared Mutable Table References
Looking at the keybindings module initialization at line 37:

```lua
config.leader = { key = mod.leader_key, mods = mod.leader_mod, timeout_milliseconds = 5000 }
```

If any module is mutating this table reference or if action_callback closures are capturing references to mutable state, you could get cross-talk between actions.

## Evidence Supporting This Analysis

1. **Multiple modules use identical LEADER activation pattern** - All key table modules insert a keybinding with the same pattern
2. **Keybindings module initializes first (but order isn't guaranteed)** - No explicit ordering in `init.lua` module application
3. **Key tables aren't namespaced to avoid overlap** - Multiple "ActivateKeyTable" calls in config.keys array
4. **No conflict detection or deduplication** - Framework doesn't warn when duplicate key+mods are registered

## The Solution

**Use unique secondary keybindings or a unified key table approach instead of individual ActivateKeyTable calls per module.**

### Option A: Convert to Unified Key Table (Recommended)

Instead of each module having its own key table activated individually, use a single unified key table that dispatches to sub-tables:

```lua
-- One mega key table in keybindings module
config.key_tables.leader = {
  { key = "g", action = act.ActivateKeyTable({ name = "git", ... }) },
  { key = "c", action = act.ActivateKeyTable({ name = "claude", ... }) },
  { key = "d", action = act.ActivateKeyTable({ name = "docker", ... }) },
  { key = "f", action = act.ActivateKeyTable({ name = "file-manager", ... }) },
  { key = "e", action = act.ActivateKeyTable({ name = "editors", ... }) },
  { key = "t", action = act.ActivateKeyTable({ name = "domains", ... }) },
  ...
}
```

Advantages:
- Single point of entry for LEADER keybindings
- No conflicts in `config.keys`
- Clear namespace hierarchy (LEADER → specific module key table)
- Easier to debug and understand flow

### Option B: Deduplicate and Order Explicitly

Ensure modules don't directly activate on their leader key - instead, let keybindings module handle LEADER routing:

```lua
-- keybindings/init.lua - Handle ALL LEADER routing
config.key_tables = config.key_tables or {}
config.key_tables.leader = {}

-- Then other modules add entries to leader table instead of config.keys
-- modules.git:
table.insert(config.key_tables.leader, {
  key = "g",
  action = act.ActivateKeyTable({ name = "git", ... })
})
```

### Option C: Remove Direct ActivateKeyTable from config.keys

Move all module-specific keybindings into a shared dispatch system that prevents conflicts:

```lua
-- keybindings/init.lua creates ONE keybinding
table.insert(config.keys, {
  key = mod.leader_key,
  mods = mod.leader_mod,
  action = act.ActivateKeyTable({
    name = "leader",
    one_shot = false,
    until_unknown = true,
  })
})

-- Then all module interactions happen through the unified leader table
```

## Recommended Implementation

1. **Modify `keybindings/init.lua`**: Create a unified "leader" key table that handles all LEADER + key combinations
2. **Update affected modules** (git, claude, docker, file-manager, editors, domains): Instead of registering their own LEADER keybinding in `config.keys`, register their key table and let the unified leader table dispatch to it
3. **Update `module.lua`**: Add a hook/phase to allow modules to register with the leader dispatcher
4. **Test**: Verify no keybinding conflicts and actions trigger correctly

This approach mirrors how modal editors like Vim/Neovim and Emacs handle keybinding hierarchies - all LEADER commands go through a unified dispatcher.
