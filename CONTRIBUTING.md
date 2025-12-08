# Contributing to WezMacs

Thank you for your interest in contributing! This guide will help you create new modules or improve existing ones.

## Table of Contents

- [Module Creation Guide](#module-creation-guide)
- [Module Anatomy](#module-anatomy)
- [Writing Good Modules](#writing-good-modules)
- [Documentation Standards](#documentation-standards)
- [Testing Your Module](#testing-your-module)
- [Submitting a Pull Request](#submitting-a-pull-request)

## Module Creation Guide

### Step 1: Create Module Directory

Create a new directory for your module in `wezmacs/modules/`:

```bash
mkdir -p wezmacs/modules/your-module-name
```

### Step 2: Create init.lua

Start with the template from `wezmacs/templates/module.lua`:

```lua
-- wezmacs/modules/your-module-name/init.lua
local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
  name = "your-module-name",
  description = "What this module does",
  deps = { "tool1", "tool2" },

  opts = {
    some_option = "default_value",
    another_option = 42,
  },

  keys = function(opts)
    return {
      -- List items are direct keybindings
      { key = "y", mods = "LEADER", action = act.SomeAction(), desc = "action" },
      -- String keys create nested key tables
      LEADER = {
        y = {
          { key = "a", action = act.OtherAction(), desc = "nested-action" },
        },
      },
    }
  end,

  setup = function(config, opts)
    -- Modify config based on opts
    config.some_setting = opts.some_option
  end,
}
```

### Step 3: Create README.md

Document your module in `wezmacs/modules/your-module-name/README.md`:

```markdown
# your-module-name module

Brief description of what this module does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Configuration

Enable in `~/.config/wezmacs/modules.lua`:
```lua
return {
  "term",
  { name = "your-module-name", opts = { some_option = "custom" } },
}
```

Or configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  ["your-module-name"] = {
    some_option = "custom",
  },
}
```

## Keybindings

| Binding | Action |
|---------|--------|
| LEADER+x | Description |

## External Dependencies

- **tool1**: What it does
- **tool2**: What it does

## Installation

```bash
brew install tool1 tool2
```

## Related Modules

- Other related modules
```

### Step 4: Test Your Module

Test locally before submitting:

```bash
# Edit user/modules.lua to include your module
return {
  "appearance",
  { name = "your-module-name", flags = {} },
}

# Edit user/config.lua to configure your module
return {
  ["your-module-name"] = {
    leader_key = "y",
  },
}

# Reload WezTerm to test
```

### Step 5: Submit Pull Request

See [Submitting a Pull Request](#submitting-a-pull-request).

## Module Anatomy

### Required Elements

1. **Metadata Fields**
   - `name`: Must match directory name
   - `description`: One-line description
   - `deps`: List of external tool dependencies

2. **Module Functions** (all optional but at least one needed)
   - `opts`: Table or function returning table with default configuration
   - `keys`: Table or function(opts) returning keybindings
   - `setup`: Function(config, opts) that modifies WezTerm config

### Optional Elements

1. **Public Functions**
   - Functions other modules might call
   - Document as part of module API

## Writing Good Modules

### 1. Single Responsibility

Each module should do ONE thing well:

```lua
-- ✓ Good: Focused module
M._DESCRIPTION = "Git workflow integration (lazygit, diff)"

-- ✗ Bad: Too many concerns
M._DESCRIPTION = "Git, SSH, Docker, and Kubernetes management"
```

### 2. Clear Dependencies

Always declare external dependencies:

```lua
M._EXTERNAL_DEPS = { "lazygit", "git", "delta" }
```

### 3. Sensible Defaults

Define good defaults in `opts` (framework handles merging):

```lua
opts = {
  leader_key = "g",
  leader_mod = "LEADER",
}

-- Framework merges user opts from modules.lua or config.lua with these defaults
-- Access merged opts via function parameters
keys = function(opts)
  -- opts.leader_key will be user's value or "g" if not specified
  return {
    { key = opts.leader_key, mods = opts.leader_mod, action = act.SomeAction(), desc = "action" },
  }
end
```

### 4. Safe Table Operations

Always check tables exist before modifying:

```lua
config.keys = config.keys or {}
table.insert(config.keys, binding)

config.key_tables = config.key_tables or {}
config.key_tables.my_table = { ... }
```

### 5. Handle Missing Dependencies

Gracefully degrade if tools aren't available:

```lua
keys = function(opts)
  local has_lazygit = wezterm.run_child_process({ "which", "lazygit" })
  if not has_lazygit then
    wezterm.log_warn("lazygit not found, skipping git shortcuts")
    return {}
  end

  return {
    { key = opts.leader_key, mods = opts.leader_mod, action = act.SomeAction(), desc = "action" },
  }
end
```

### 6. Use Helper Functions

Use `wezmacs.action` for custom actions:

```lua
local wezmacs = require("wezmacs")

keys = function(opts)
  return {
    { key = "g", mods = "LEADER", action = wezmacs.action.SmartSplit("lazygit"), desc = "git" },
    { key = "t", mods = "LEADER", action = wezmacs.action.NewTab("htop"), desc = "htop" },
  }
end
```

### 7. Logging for Debugging

Use wezterm logging functions:

```lua
setup = function(config, opts)
  wezterm.log_info("Applying module configuration")

  if not opts.some_option then
    wezterm.log_warn("some_option not specified, using default")
  end

  -- Apply configuration...
end
```

### 8. Documentation in Code

Comment complex logic:

```lua
-- Smart orientation: split horizontally if portrait, vertically if landscape
local direction = dims.pixel_height > dims.pixel_width and "Bottom" or "Right"
```

## Documentation Standards

### README Structure

Every module README should include (in order):

1. **Title & Description** (one line)
2. **Features** (bulleted list)
3. **Configuration** (code example)
4. **Keybindings** (table if applicable)
5. **External Dependencies** (bulleted list with links)
6. **Installation** (bash commands)
7. **Related Modules** (references to complementary modules)

### Quality Standards

- Clear, concise language
- Real examples users can copy-paste
- Accurate descriptions
- Links to external tools
- Installation commands for macOS (Homebrew) minimum

## Testing Your Module

### Local Testing

1. Create `~/.config/wezmacs/modules.lua`:
   ```lua
   return {
     "term",
     { name = "your-module-name", opts = { some_option = "test" } },
   }
   ```

2. Optionally create `~/.config/wezmacs/config.lua`:
   ```lua
   return {
     ["your-module-name"] = {
       some_option = "test",
     },
   }
   ```

3. Reload WezTerm configuration

4. Test all features:
   - Try keybindings
   - Check logs for errors
   - Verify colors/styling applied
   - Test with default opts vs custom opts

### Syntax Validation

Use `luacheck`:

```bash
luacheck wezmacs/modules/your-module-name/init.lua
```

### Manual Review Checklist

- [ ] name, description, deps fields complete
- [ ] opts defined with sensible defaults
- [ ] keys function returns proper format (list items + nested tables)
- [ ] setup function modifies config correctly
- [ ] Safe table operations
- [ ] Error handling for missing deps
- [ ] Comments for complex logic
- [ ] README documented
- [ ] No external Lua dependencies (use wezterm APIs)
- [ ] Follows existing module patterns
- [ ] Works in test config

## Submitting a Pull Request

### Before Submitting

1. **Verify module works locally** (see Testing Your Module)
2. **Review module naming** - should be kebab-case
3. **Check README quality** - use the standards above
4. **Validate Lua syntax** - use luacheck if available
5. **Update documentation** - reference new module in README if needed

### PR Title Format

```
feat(modules): add [module-name] for [feature description]
```

Examples:
```
feat(modules): add rainbow-parens for colorful bracket matching
feat(modules): add tmux-navigation for tmux pane integration
```

### PR Description Template

```markdown
## Summary
Brief description of what this module does.

## Features
- Feature 1
- Feature 2
- Feature 3

## Configuration Example

Enable in `~/.config/wezmacs/modules.lua`:
```lua
return {
  "term",
  { name = "module-name", opts = { option = "value" } },
}
```

Or configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  ["module-name"] = {
    option = "value",
  },
}
```

## External Dependencies
- tool1 (link)
- tool2 (link)

## Testing
- [x] Tested locally with config
- [x] README documentation complete
- [x] Keybindings verified
- [x] External deps declared

## Checklist
- [x] Follows module template
- [x] Metadata fields complete
- [x] Safe table operations
- [x] Sensible defaults
- [x] README formatted correctly
- [x] No lint errors
```

### What We Look For

1. **Clarity**: Is the module's purpose clear?
2. **Quality**: Does it follow WezMacs patterns?
3. **Documentation**: Is it well-documented?
4. **Testing**: Has the author tested it?
5. **Scope**: Does it do one thing well?

### Feedback & Revision

We may ask for:
- Refactoring for clarity
- Better defaults
- More comprehensive documentation
- Testing confirmation
- Naming improvements

Please be open to feedback - we want WezMacs modules to be excellent!

## Module Naming

Good names are:

- **Descriptive**: `mouse-bindings` not `mb`
- **Lowercase**: `my-feature` not `MyFeature`
- **Kebab-case**: `my-feature-name` not `my_feature_name`
- **Specific**: `workspace-switcher` not `workspace-management`
- **Concise**: `git-shortcuts` not `git-workflow-integration-shortcuts`

## Code Style

Follow the style of existing modules:

- **Indentation**: 2 spaces
- **Line Length**: ~100 chars (reasonable wrapping)
- **Comments**: Use for complex logic, not obvious code
- **Naming**: Use descriptive names, avoid abbreviations
- **Structure**: metadata → apply

### Example Style

```lua
local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
  name = "example",
  description = "Example module",
  deps = { "tool1" },

  opts = {
    some_option = "default_value",
    another_option = 42,
  },

  keys = function(opts)
    return {
      { key = "a", mods = "CMD", action = act.SomeAction(), desc = "action" },
      LEADER = {
        e = {
          { key = "e", action = act.OtherAction(), desc = "nested-action" },
        },
      },
    }
  end,

  setup = function(config, opts)
    config.some_setting = opts.some_option
  end,
}
```

## Questions?

- See [FRAMEWORK.md](FRAMEWORK.md) for architecture details
- See [README.md](README.md) for usage examples
- Review existing modules in `wezmacs/modules/` for reference

Thank you for contributing to WezMacs! 🎉
