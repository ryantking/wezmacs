# Plan: Fix Keybinding Shifting Bug

**Date:** 2025-12-05
**Status:** Ready for Implementation
**Related Research:**
- `.claude/research/KEYBINDING_BUG_ANALYSIS.md`
- `.claude/research/2025-12-02-wezterm-keybinding-precedence.md`
- `.claude/research/2025-12-05-keybinding-conflict-analysis.md`

## Problem Summary

Keybindings randomly shift after using WezTerm for a while. For example, `LEADER c w` (claude workspace creation) sometimes triggers `move_to_new_window` instead. The previous fix (shallow copy in `wezmacs.get_module()`) was insufficient.

## Root Causes Identified

1. **Duplicate LEADER keybindings** between `keybindings` module and other modules
2. **Non-deterministic module load order** via Lua's `pairs()` iteration

## Implementation Plan

### Phase 1: Remove Conflicting Keybindings (Option A)

**Goal:** Eliminate duplicate LEADER keybindings from the `keybindings` module

**Files to modify:**
- `wezmacs/modules/keybindings/init.lua`

**Changes:**

1. **Remove `LEADER f` binding** (line 98)
   - Currently: `{ key = "f", mods = "LEADER", action = act.ToggleFullScreen }`
   - Conflicts with: `file-manager` module's `ActivateKeyTable("file-manager")`
   - Resolution: Remove from keybindings, keep in file-manager
   - Alternative: Move ToggleFullScreen to `LEADER F` (capital) if still desired

2. **Remove `LEADER t` binding** (line 105)
   - Currently: `{ key = "t", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") }`
   - Conflicts with: `domains` module (uses `t` for domain key table)
   - Resolution: Remove from keybindings, keep SpawnTab on `CTRL|SHIFT t` only
   - Note: `LEADER T` (capital) for DefaultDomain can remain

3. **Audit remaining LEADER bindings for future conflicts:**

   | Key | Action | Potential Conflict |
   |-----|--------|-------------------|
   | `LEADER r` | ReloadConfiguration | None |
   | `LEADER L` | ShowDebugOverlay | None |
   | `LEADER Enter` | ActivateCommandPalette | None |
   | `LEADER u` | CharSelect | None |
   | `LEADER Space` | QuickSelect | None |
   | `LEADER /` | Search | None |
   | `LEADER l` | QuickSelectArgs | None |
   | `LEADER v` | ActivateCopyMode | None |
   | `LEADER y/p` | Clipboard | None |
   | `LEADER Y/P` | PrimarySelection | None |
   | `LEADER n` | SpawnWindow | None |
   | `LEADER T` | SpawnTab(DefaultDomain) | None (capital T) |
   | `LEADER [/]` | ActivateTabRelative | None |
   | `LEADER {/}` | MoveTabRelative | None |
   | `LEADER 1-9` | ActivateTab | None |
   | `LEADER -` | SplitVertical | None |
   | `LEADER \` | SplitHorizontal | None |
   | `LEADER z` | TogglePaneZoomState | None |
   | `LEADER x` | CloseCurrentPane | None |
   | `LEADER N` | move_to_new_tab | None |
   | `LEADER W` | move_to_new_window | None |

**Reserved keys for module key tables:**
- `g` - git
- `c` - claude
- `d` - docker
- `f` - file-manager
- `t` - domains
- `e` - editors (direct binding, not key table)
- `s/S` - workspace (direct binding)

---

### Phase 2: Deterministic Module Loading (Option B)

**Goal:** Ensure modules load in a consistent, predictable order

**Files to modify:**
- `wezmacs/module.lua`

**Changes:**

1. **Add explicit load order configuration** (new)

   ```lua
   -- Default load order (can be overridden by user)
   local DEFAULT_LOAD_ORDER = {
     "core",        -- Must be first (base settings)
     "theme",       -- Visual settings early
     "keybindings", -- Core keybindings before modules that extend them
     "workspace",   -- Workspace management
     "git",
     "claude",
     "docker",
     "file-manager",
     "editors",
     "domains",
     "k8s",
     "session",
     "status",
   }
   ```

2. **Modify `load_all()` function** to use ordered iteration

   Replace:
   ```lua
   for mod_name, mod_user_config in pairs(unified_config) do
   ```

   With:
   ```lua
   -- Build ordered list: explicit order first, then remaining modules
   local ordered_modules = {}
   local seen = {}

   -- Add modules in explicit order
   for _, mod_name in ipairs(load_order) do
     if unified_config[mod_name] then
       table.insert(ordered_modules, mod_name)
       seen[mod_name] = true
     end
   end

   -- Add any remaining modules not in explicit order
   for mod_name, _ in pairs(unified_config) do
     if not seen[mod_name] then
       table.insert(ordered_modules, mod_name)
     end
   end

   -- Load in order
   for _, mod_name in ipairs(ordered_modules) do
     local mod_user_config = unified_config[mod_name]
     -- ... existing load logic
   end
   ```

3. **Add optional user override** for load order

   Allow users to specify custom load order in their config:
   ```lua
   -- In user's wezmacs.lua
   return {
     _load_order = {"core", "keybindings", ...}, -- Optional
     core = { ... },
     keybindings = { ... },
   }
   ```

---

### Testing Plan

1. **Before changes:**
   - Document current behavior with `debug_key_events = true`
   - Note which bindings are active for `LEADER f`, `LEADER t`

2. **After Phase 1:**
   - Verify `LEADER f` consistently activates file-manager key table
   - Verify `LEADER t` consistently activates domains key table
   - Verify removed bindings are accessible via alternative keys

3. **After Phase 2:**
   - Reload config multiple times
   - Verify module load order is consistent (check logs)
   - Verify keybinding behavior is deterministic

4. **Regression testing:**
   - Test all LEADER bindings still work
   - Test all key tables (git, claude, docker, file-manager, domains)
   - Test editors module direct bindings

---

## Future Work: Option C - Unified Leader Key Table

**Not implementing now, but documenting for future consideration.**

### Concept

Instead of each module adding its own `LEADER + x` binding to `config.keys`, use a single unified "leader" key table:

```lua
-- In keybindings module or new leader module
config.key_tables.leader = {
  -- Direct actions
  { key = "r", action = act.ReloadConfiguration },
  { key = "Space", action = act.QuickSelect },
  -- ... other direct actions

  -- Sub-table activations
  { key = "g", action = act.ActivateKeyTable({ name = "git", ... }) },
  { key = "c", action = act.ActivateKeyTable({ name = "claude", ... }) },
  { key = "d", action = act.ActivateKeyTable({ name = "docker", ... }) },
  { key = "f", action = act.ActivateKeyTable({ name = "file-manager", ... }) },
  { key = "t", action = act.ActivateKeyTable({ name = "domains", ... }) },
}

-- Single entry point
table.insert(config.keys, {
  key = mod.leader_key,
  mods = mod.leader_mod,
  action = act.ActivateKeyTable({ name = "leader", one_shot = false, until_unknown = true })
})
```

### Benefits

1. **No conflicts** - Single point of entry for all LEADER commands
2. **Clear hierarchy** - LEADER → sub-table → action
3. **Easier debugging** - One place to see all LEADER bindings
4. **Module independence** - Modules only define their key table contents, not activation

### Challenges

1. **API change** - Modules would need to register with leader table instead of `config.keys`
2. **Hook mechanism needed** - Modules need way to add entries to leader table
3. **Two-level activation** - User presses LEADER, then enters "leader" key table, then presses key

### Implementation Sketch

```lua
-- In wezmacs/init.lua or new leader.lua module
local leader_entries = {}

_G.wezmacs = {
  -- Existing API...

  -- New API for modules to register leader bindings
  register_leader_binding = function(entry)
    table.insert(leader_entries, entry)
  end,

  -- Called after all modules loaded to build leader table
  finalize_leader_table = function(config)
    config.key_tables.leader = leader_entries
  end,
}
```

This requires more architectural changes and should be considered for a future major version.

---

## Implementation Checklist

- [ ] Phase 1: Remove conflicting keybindings
  - [ ] Remove `LEADER f` from keybindings/init.lua
  - [ ] Remove `LEADER t` from keybindings/init.lua
  - [ ] Add `LEADER F` for ToggleFullScreen (optional)
  - [ ] Update documentation/comments

- [ ] Phase 2: Deterministic module loading
  - [ ] Add DEFAULT_LOAD_ORDER to module.lua
  - [ ] Modify load_all() for ordered iteration
  - [ ] Support _load_order user override (optional)
  - [ ] Add logging for load order visibility

- [ ] Testing
  - [ ] Test all key tables activate correctly
  - [ ] Test multiple config reloads
  - [ ] Verify no regressions in existing bindings

- [ ] Documentation
  - [ ] Update CLAUDE.md if needed
  - [ ] Document reserved LEADER keys
