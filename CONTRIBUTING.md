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
local M = {}

-- Metadata
M._NAME = "your-module-name"
M._CATEGORY = "workflows"  -- or ui, behavior, editing, integration
M._DESCRIPTION = "What this module does"
M._EXTERNAL_DEPS = { "tool1", "tool2" }  -- External tool dependencies

-- Feature flags (optional features users can enable)
-- Can be simple flags or complex objects with config_schema and deps
M._FEATURES = {
  smartsplit = true,  -- Simple flag
  advanced = {
    config_schema = {
      advanced_option = "default",
    },
    deps = { "smartsplit" },  -- Requires smartsplit to be enabled
  },
}

-- Configuration schema with defaults
M._CONFIG_SCHEMA = {
  leader_key = "y",
  leader_mod = "LEADER",
}

-- Apply phase (required) - modify WezTerm config
function M.apply_to_config(config)
  -- Get merged configuration from framework
  local module_config = wezmacs.get_config("your-module-name")
  local enabled_flags = wezmacs.get_enabled_flags("your-module-name")

  -- Check for enabled feature flags
  if enabled_flags.smartsplit then
    -- Enable smart-split functionality
  end

  -- Use configuration values from module_config
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = module_config.leader_key,
    mods = module_config.leader_mod,
    action = wezterm.action.ActivateKeyTable({ name = "your-module" }),
  })

  -- Feature-specific config is at config.features.feature_name
  if enabled_flags.advanced then
    local advanced_config = config.features.advanced
    -- Use advanced_config.advanced_option
  end
end

return M
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
  "appearance",
  { name = "your-module-name", flags = { "smartsplit" } },
}
```

Configure in `~/.config/wezmacs/config.lua`:
```lua
return {
  ["your-module-name"] = {
    leader_key = "y",
    leader_mod = "LEADER",
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
   - `_NAME`: Must match directory name
   - `_CATEGORY`: One of ui, behavior, editing, integration, workflows
   - `_DESCRIPTION`: One-line description
   - `_EXTERNAL_DEPS`: List of external tools
   - `_FEATURES`: Map of feature_name = true or { config_schema = {}, deps = {} }
   - `_CONFIG_SCHEMA`: Map of config_key = default_value

2. **apply_to_config Function**
   - Always required
   - Receives: config (WezTerm config)
   - Uses `wezmacs.get_config(module_name)` to access merged configuration
   - Uses `wezmacs.get_enabled_flags(module_name)` to check enabled features
   - Modifies config object
   - No return value

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

Define good defaults in _CONFIG_SCHEMA (framework handles merging):

```lua
M._CONFIG_SCHEMA = {
  leader_key = "g",
  leader_mod = "LEADER",
}

-- Framework merges user config from config.lua with these defaults
-- Access merged config via wezmacs.get_config(module_name)
function M.apply_to_config(config)
  local cfg = wezmacs.get_config("your-module")
  -- cfg.leader_key will be user's value or "g" if not specified
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
function M.apply_to_config(config)
  local has_lazygit = wezterm.run_child_process({ "which", "lazygit" })
  if not has_lazygit then
    wezterm.log_warn("lazygit not found, skipping git shortcuts")
    return
  end

  -- Get merged configuration from framework
  local cfg = wezmacs.get_config("git")

  -- Add git keybindings using cfg
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = cfg.leader_key,
    mods = cfg.leader_mod,
    action = wezterm.action.ActivateKeyTable({ name = "git" }),
  })
end
```

### 6. Use Helper Functions

Use utilities from `wezmacs/utils/`:

```lua
local keys_util = require("wezmacs.utils.keys")
local colors_util = require("wezmacs.utils.colors")

-- Create keybindings using helpers
table.insert(config.keys, keys_util.chord("g", "LEADER", action))

-- Manipulate colors
local dark_bg = colors_util.darken(theme.background, 0.2)
```

### 7. Logging for Debugging

Use wezterm logging functions:

```lua
function M.apply_to_config(config)
  wezterm.log_info("Applying module configuration")

  local cfg = wezmacs.get_config("modulename")
  if not cfg.option then
    wezterm.log_warn("option not specified, using default")
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

1. Create `user/modules.lua`:
   ```lua
   return {
     "appearance",
     { name = "your-module-name", flags = { "feature1" } },
   }
   ```

2. Create `user/config.lua`:
   ```lua
   return {
     ["your-module-name"] = {
       leader_key = "y",
       leader_mod = "LEADER",
     },
   }
   ```

3. Reload WezTerm configuration

4. Test all features:
   - Try keybindings
   - Check logs for errors
   - Verify colors/styling applied
   - Test with/without flags
   - Test with default config vs custom config

### Syntax Validation

Use `luacheck`:

```bash
luacheck wezmacs/modules/your-module-name/init.lua
```

### Manual Review Checklist

- [ ] Metadata fields complete
- [ ] Dependencies declared
- [ ] Defaults provided
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
  "appearance",
  { name = "module-name", flags = { "feature1" } },
}
```

Configure in `~/.config/wezmacs/config.lua`:
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
local M = {}

M._NAME = "example"
M._CATEGORY = "workflows"
M._DESCRIPTION = "Example module"
M._EXTERNAL_DEPS = {}

M._FEATURES = {
  feature1 = true,
  advanced = {
    config_schema = {
      advanced_option = "default",
    },
  },
}

M._CONFIG_SCHEMA = {
  some_option = "default_value",
}

function M.apply_to_config(config)
  -- Get merged configuration from framework
  local cfg = wezmacs.get_config("example")
  local flags = wezmacs.get_enabled_flags("example")

  -- Check feature flags
  if flags.feature1 then
    -- Enable feature1
  end

  -- Use configuration values
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = "a",
    mods = "CMD",
    action = wezterm.action.SomeAction(),
  })

  -- Feature-specific config
  if flags.advanced then
    local advanced_cfg = config.features.advanced
    -- Use advanced_cfg.advanced_option
  end
end

return M
```

## Questions?

- See [FRAMEWORK.md](FRAMEWORK.md) for architecture details
- See [README.md](README.md) for usage examples
- Review existing modules in `wezmacs/modules/` for reference

Thank you for contributing to WezMacs! 🎉
