# Research: Keybinding Conflict Analysis (Post-Shallow-Copy Fix)

**Date:** 2025-12-05
**Context:** Bug persists after shallow copy fix in commit 3d926bf
**Agent:** Main + Explore + Historian

## Summary

The shallow copy fix addressed closure capture issues but did NOT fix the keybinding shifting bug. Investigation revealed two additional root causes: duplicate LEADER keybindings and non-deterministic module loading.

## Investigation Findings

### 1. Confirmed Duplicate Keybindings

| Key | Module 1 | Line | Module 2 | Line | Winner |
|-----|----------|------|----------|------|--------|
| `LEADER f` | keybindings | 98 | file-manager | 60-68 | Non-deterministic |
| `LEADER t` | keybindings | 105 | domains | varies | Non-deterministic |

**keybindings/init.lua:98:**
```lua
table.insert(config.keys, { key = "f", mods = "LEADER", action = act.ToggleFullScreen })
```

**file-manager/init.lua:60-68:**
```lua
table.insert(wezterm_config.keys, {
  key = mod.leader_key,  -- "f"
  mods = mod.leader_mod, -- "LEADER"
  action = act.ActivateKeyTable({ name = "file-manager", ... })
})
```

### 2. Non-Deterministic Module Load Order

**Location:** `wezmacs/module.lua:54`

```lua
for mod_name, mod_user_config in pairs(unified_config) do
```

Lua's `pairs()` does not guarantee iteration order. From the Lua 5.1 manual:
> "The order in which the indices are enumerated is not specified, even for numeric indices."

**Impact:**
- Module load order varies between config reloads
- Keybindings inserted via `table.insert()` appear in different positions
- If WezTerm uses first-match-wins, the "winning" binding changes randomly

### 3. WezTerm Keybinding Resolution (Empirical)

Based on research and community patterns:
- `config.keys` is an array iterated in order
- First match wins (not explicitly documented but inferred)
- Key tables are searched from top of stack down
- Config reloads clear key table stack

### 4. Module LEADER Key Assignments

**Key Table Modules (use `mod.leader_key` + `mod.leader_mod`):**

| Module | Default leader_key | Default leader_mod |
|--------|-------------------|-------------------|
| git | "g" | "LEADER" |
| claude | "c" | "LEADER" |
| docker | "d" | "LEADER" |
| file-manager | "f" | "LEADER" |
| domains | "t" | "LEADER" |

**Direct Binding Modules (hardcoded mods = "LEADER"):**

| Module | Keys | Purpose |
|--------|------|---------|
| keybindings | r, L, Enter, u, Space, /, l, v, y, p, Y, P, n, f, t, T, [, ], {, }, 1-9, -, \, z, x, N, W | Core bindings |
| editors | e, E, i | Editor launchers |
| workspace | s, S | Workspace switcher |

### 5. Shallow Copy Fix Verification

**Location:** `wezmacs/init.lua:54-59`

```lua
get_module = function(module_name)
  local state = states[module_name]
  if not state then
    return { features = {} }
  end
  -- Return shallow copy to avoid shared mutable state in closures
  local copy = {}
  for k, v in pairs(state) do
    copy[k] = v
  end
  return copy
end
```

**Status:** Fix is in place and working correctly for its intended purpose.

**What it fixes:** Closures capturing module config no longer share mutable references.

**What it doesn't fix:** Duplicate keybindings and non-deterministic load order.

## External Research: WezTerm Known Issues

### Relevant GitHub Issues

1. **[Issue #4624](https://github.com/wezterm/wezterm/issues/4624)** - ActivateKeyTable activates without modifier
   - Reported on macOS
   - Key table activates when pressing the key alone (without LEADER/modifier)
   - May be related to typo (`mod` vs `mods`)

2. **[Issue #6824](https://github.com/wezterm/wezterm/issues/6824)** - key_tables bindings not working with modifiers
   - Linux Wayland + KDE Plasma
   - Bindings with `mods` property in key_table don't trigger
   - All other keybindings work

3. **[Issue #1391](https://github.com/wezterm/wezterm/issues/1391)** - SHIFT key bindings don't work
   - CTRL+SHIFT combinations fail to trigger
   - Related to shifted characters vs explicit SHIFT modifier

4. **[Issue #394](https://github.com/wezterm/wezterm/issues/394)** - Leader key with shifted keys
   - LEADER + shifted character bindings don't trigger
   - Workaround: Use `mapped:` prefix

### WezTerm Documentation Notes

- `key_map_preference` controls how keys without prefix are treated
- Default is "Mapped" (character-based matching)
- "Physical" matches key position regardless of layout
- Duplicate keybinding resolution is NOT documented

## Conclusions

### Why Bug Persists After Shallow Copy Fix

1. The original bug hypothesis (shared mutable state in closures) was partially correct
2. But there were multiple contributing factors:
   - Shared mutable state (FIXED by shallow copy)
   - Duplicate keybindings (NOT FIXED)
   - Non-deterministic load order (NOT FIXED)

3. The shallow copy fix may have reduced frequency but didn't eliminate the bug

### Recommended Actions

1. **Immediate:** Remove duplicate keybindings from keys module
2. **Short-term:** Implement deterministic module loading
3. **Long-term:** Consider unified leader key table architecture

### Reserved LEADER Keys

To prevent future conflicts, document these as reserved:

```
Reserved for key table modules:
  g - git
  c - claude
  d - docker
  f - file-manager
  t - domains

Reserved for direct binding modules:
  e, E, i - editors
  s, S - workspace
```

## Test Methodology

To verify the bug and fix:

1. Enable debug logging:
   ```lua
   config.debug_key_events = true
   ```

2. Test LEADER bindings before/after config reload:
   ```
   LEADER f - should activate file-manager OR toggle fullscreen (inconsistent = bug)
   LEADER t - should activate domains OR spawn tab (inconsistent = bug)
   ```

3. Check module load order in logs after implementing fix

## Files Referenced

- `wezmacs/init.lua:54-59` - Shallow copy fix
- `wezmacs/module.lua:54` - Non-deterministic pairs() loop
- `wezmacs/modules/keys/init.lua:98,105` - Conflicting bindings
- `wezmacs/modules/file-manager/init.lua:60-68` - file-manager LEADER f
- `wezmacs/modules/git/init.lua:55-63` - git LEADER g
- `wezmacs/modules/claude/init.lua:54-62` - claude LEADER c
- `wezmacs/modules/docker/init.lua:44-52` - docker LEADER d
