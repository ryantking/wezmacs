# Research: WezTerm Keybinding Precedence and Module-Based Configuration

Date: 2025-12-02
Focus: How WezTerm resolves keybinding conflicts and best practices for modular keybinding systems
Agent: researcher

## Summary

WezTerm uses a key table stack architecture where the top of stack is searched first for matches, falling through to lower entries. For duplicate keybindings within the same `config.keys` array, the documentation does not explicitly state first-wins vs last-wins behavior - this requires empirical testing. Lua closures can capture mutable table references, which may cause issues if tables are modified after closure creation.

## Key Findings

### 1. Key Table Stack Architecture

WezTerm maintains a **stack of key table activations** per GUI window. Resolution works as follows:

- Top of stack is searched first for a match
- If no match found, the next entry on the stack is searched
- This continues until a match is found or the stack is exhausted
- If no match in any key table, falls back to default bindings

This behavior was improved in version `20220624-141144-bd1b7c5d`. Prior releases only checked the topmost stack entry before falling back to defaults.

[Source: Key Tables Documentation](https://wezterm.org/config/key-tables.html)

### 2. Key Type Precedence Order

When resolving which key specification matches a physical keypress:

**Precedence order: physical -> raw -> mapped**

- `phys:` prefix matches physical key position regardless of layout
- `raw:` prefix matches raw keycode from OS
- `mapped:` (default) matches the character produced by keyboard layout

[Source: Key Binding Documentation](https://wezterm.org/config/keys.html)

### 3. Duplicate Keybinding Resolution (UNDOCUMENTED)

**Critical finding**: The official documentation does NOT explicitly document what happens when multiple keybindings in `config.keys` target the same key+modifiers combination.

Based on community patterns and how Lua tables work:
- When using simple `table.insert()` merging, later entries are appended
- WezTerm likely uses **first-match-wins** semantics (array iteration order)
- This means earlier entries in `config.keys` take precedence

**Recommendation**: Test empirically with `debug_key_events = true` or examine WezTerm source code for definitive behavior.

### 4. ActivateKeyTable Known Issues

| Issue | Description | Resolution |
|-------|-------------|------------|
| `mod` vs `mods` typo | Using singular `mod = "LEADER"` instead of `mods = "LEADER"` causes keybinding to activate without modifier | Use correct plural `mods` |
| `replace_current` field | Documentation says optional but some versions required it | Explicitly set if errors occur |
| Config reload clears stack | Key table stack is cleared on config reload | Can be used to "unstick" from modal states |

[Source: GitHub Issue #4624](https://github.com/wezterm/wezterm/issues/4624)

### 5. Lua Closure and Table Reference Issues

When creating callbacks/closures that reference tables:

```lua
-- POTENTIAL BUG: closure captures reference to `bindings` table
for i, binding in ipairs(bindings) do
    table.insert(config.keys, {
        key = binding.key,
        mods = binding.mods,
        action = function()
            -- If `bindings` is mutated later, this closure sees mutations
            return binding.action
        end
    })
end
```

**Key points:**
- Lua closures capture **references** to upvalues, not copies
- If the referenced table is mutated after closure creation, all closures see the mutation
- Loop variables in Lua are shared across iterations (unlike some other languages)
- For async callbacks, the Lua VM state may change between closure creation and invocation

**Safe pattern:**
```lua
-- Create local copy to avoid shared reference issues
for i, binding in ipairs(bindings) do
    local captured_binding = binding  -- Local copy
    table.insert(config.keys, {
        key = captured_binding.key,
        mods = captured_binding.mods,
        action = captured_binding.action
    })
end
```

[Sources: Lua PIL](https://www.lua.org/pil/6.1.html), [Closures in Lua](https://www.cs.tufts.edu/~nr/cs257/archive/roberto-ierusalimschy/closures-draft.pdf)

### 6. Module-Based Keybinding Best Practices

**Recommended pattern from community:**

```lua
-- merge.lua utility
local M = {}

function M.all(base, overrides)
    local ret = base or {}
    local second = overrides or {}
    for _, v in pairs(second) do
        table.insert(ret, v)
    end
    return ret
end

return M
```

**Usage:**
```lua
local merge = require('merge')
config.keys = {}
config.keys = merge.all(config.keys, core_keybindings)
config.keys = merge.all(config.keys, editor_keybindings)
config.keys = merge.all(config.keys, custom_keybindings)
```

**Best practices:**
1. Initialize `config.keys = {}` before merging
2. Use `apply_to_config(config)` pattern for modules
3. Place higher-priority bindings in modules merged first (if first-wins)
4. Use `DisableDefaultAssignment` to prevent conflicts with WezTerm defaults
5. Consider `disable_default_key_bindings = true` for full control

[Source: Managing WezTerm Keybindings](https://mwop.net/blog/2024-10-21-wezterm-keybindings.html)

### 7. Other Known Keybinding Issues

| Issue | Description | Status |
|-------|-------------|--------|
| Leader + shifted keys | Leader key bindings with shifted characters (like `|`) may not trigger | Fixed in newer versions |
| SHIFT modifier conflicts | Including SHIFT when key implies it can cause failures | Use key without redundant SHIFT |
| CMD modifier issues | Some CMD combinations don't work as expected on macOS | Workaround: use SHIFT variant |
| Async action timing | `act.Multiple()` doesn't wait for async actions to complete | Be aware when chaining async operations |

## Detailed Analysis

### Why Keybinding Shifts/Wrong Actions May Occur

Based on research, several factors can cause wrong keybindings to trigger:

1. **Typos in field names**: Using `mod` instead of `mods` causes the modifier to be ignored entirely, making the binding trigger on the raw key.

2. **Key table stack state**: If a modal key table is active (from `ActivateKeyTable`), it takes precedence. Config reloads clear this stack.

3. **Merge order issues**: When merging keybindings from multiple modules, if WezTerm uses first-match-wins, a binding from an earlier module will shadow later ones for the same key.

4. **Lua closure mutations**: If keybinding tables are built dynamically with closures that reference shared mutable state, mutations can cause unexpected behavior.

5. **Physical vs mapped key confusion**: A keybinding specified without prefix uses `mapped:` by default. On non-US layouts, the physical key position may differ from expected character.

### Recommendations for WezMacs Framework

1. **Document merge order clearly**: Establish whether early or late modules take precedence

2. **Avoid closure captures of mutable tables**: When building keybindings programmatically, capture values explicitly

3. **Use explicit key specifications**: Consider `phys:` for position-based keys, `mapped:` for character-based

4. **Validate keybinding uniqueness**: Consider adding a validation step that warns about duplicate key+mods combinations

5. **Test with debug_key_events**: Enable `debug_key_events = true` during development to see exactly what WezTerm receives

## Applicable Patterns

For the WezMacs modular framework:

```lua
-- In module.lua or keybinding merger
local function merge_keybindings(base, additions, options)
    options = options or {}
    local result = {}
    local seen = {}

    -- If last-wins desired, process base first
    -- If first-wins desired, process additions first
    local sources = options.last_wins
        and {base, additions}
        or {additions, base}

    for _, source in ipairs(sources) do
        for _, binding in ipairs(source or {}) do
            local key_id = binding.key .. "|" .. (binding.mods or "")
            if not seen[key_id] then
                seen[key_id] = true
                table.insert(result, binding)
            end
        end
    end

    return result
end
```

## Sources

- [Key Binding - WezTerm Documentation](https://wezterm.org/config/keys.html)
- [Key Tables - WezTerm Documentation](https://wezterm.org/config/key-tables.html)
- [Default Key Assignments - WezTerm Documentation](https://wezterm.org/config/default-keys.html)
- [ActivateKeyTable - WezTerm Documentation](https://wezterm.org/config/lua/keyassignment/ActivateKeyTable.html)
- [GitHub Issue #4624 - ActivateKeyTable modifier issue](https://github.com/wezterm/wezterm/issues/4624)
- [GitHub Discussion #2397 - Multiple assignments](https://github.com/wezterm/wezterm/discussions/2397)
- [Managing WezTerm Keybindings - mwop.net](https://mwop.net/blog/2024-10-21-wezterm-keybindings.html)
- [Programming in Lua: Closures](https://www.lua.org/pil/6.1.html)
- [Closures in Lua - Academic Paper](https://www.cs.tufts.edu/~nr/cs257/archive/roberto-ierusalimschy/closures-draft.pdf)
- [Using Closures in Lua - PlayControl](https://playcontrol.net/ewing/jibberjabber/using-closures-in-lua-to-av.html)

## Confidence Level

**Medium** - The key table stack behavior is well-documented. However, the critical question of duplicate keybinding resolution within `config.keys` is NOT explicitly documented. Community patterns suggest first-match-wins but this should be verified through testing or source code review.

## Related Questions

- What does WezTerm's source code show for `config.keys` iteration order?
- Does WezTerm log warnings when duplicate keybindings are defined?
- How do other terminal emulators (kitty, alacritty) handle duplicate keybindings?
- Should WezMacs implement its own duplicate detection/warning system?
