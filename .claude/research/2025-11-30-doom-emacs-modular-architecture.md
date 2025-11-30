# Research: Doom Emacs Modular Configuration Framework
Date: 2025-11-30
Focus: Understanding Doom Emacs module system architecture for implementing similar modular config in WezTerm
Agent: researcher

## Summary
Doom Emacs uses a sophisticated three-phase module system (init.el, config.el, packages.el) with automatic discovery, flag-based customization, and lazy-loading through autoload/autodef patterns. Modules are organized by category (`:lang`, `:tools`, etc.), enabled via a declarative `doom!` block in user's init.el, and expose APIs through autodef functions that become no-ops when modules are disabled.

## Key Findings

### Module Directory Structure
- **Standard Location**: `~/.doom.d/modules/category/name/` for private modules
- **File Structure** ([source](https://discourse.doomemacs.org/t/how-to-write-your-own-modules/86)):
  ```
  category/module/
  ├── init.el       # Early initialization, before packages load
  ├── config.el     # Main configuration (runs after all modules loaded)
  ├── packages.el   # Package declarations only
  ├── autoload.el   # Lazy-loaded functions (or autoload/*.el)
  ├── doctor.el     # Health check diagnostics
  ├── cli.el        # CLI command extensions
  └── test/*.el     # Module tests
  ```

### Three-Phase Loading Pattern ([source](https://discourse.doomemacs.org/t/how-to-write-your-own-modules/86))

1. **packages.el** - Runs first, in isolation
   - Declares dependencies using `package!` macro
   - Should NOT contain configuration logic or side effects
   - Only conditional statements and package declarations
   - Example: `(package! evil)`, `(package! company :disable t)`

2. **init.el** - Runs early during Doom core initialization
   - Loaded before anything else, after Doom core
   - Use for setup operations and `use-package-hook!` reconfiguration
   - Keep lightweight - errors here can break Doom
   - Runs before packages are actually loaded

3. **config.el** - Runs last, after all modules and packages load
   - 99.99% of configuration should go here
   - Use `after!` macro to defer until package loads
   - Use `use-package!` for additional package configuration
   - Has access to all loaded modules

### User Configuration Pattern

**User's $DOOMDIR/init.el** - Declarative module selection ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/modules.org)):
```elisp
(doom! :completion
       (company +childframe)  ; with flag
       vertico

       :lang
       (python +lsp +pyright)
       rust

       :tools
       magit
       docker)
```

**User's $DOOMDIR/config.el** - Personal overrides and customization ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org)):
- Runs after all modules loaded
- Use `after!` blocks to configure packages
- Use exposed autodef functions from modules
- Example: `(after! magit (setq magit-save-repository-buffers nil))`

### Module Flags System

**Syntax** ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/modules.org)):
- Flags prefixed with `+` (add feature) or `-` (remove feature)
- Example: `(company +childframe +tng)` or `(python +lsp -conda)`
- No functional significance to notation - purely convention

**Implementation** ([source](https://discourse.doomemacs.org/t/how-to-write-your-own-modules/86)):
- Use `featurep!` macro to test for flags
- In current module: `(featurep! +my-feature)`
- In other modules: `(featurep! :lang python +lsp)`
- Makes packages and config conditional on flags

**Example** ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org)):
```elisp
;; In packages.el
(when (featurep! +childframe)
  (package! company-box))

;; In config.el
(when (featurep! +childframe)
  (use-package! company-box
    :hook (company-mode . company-box-mode)))
```

### Module Discovery and Loading

**Automatic Discovery** ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/modules.org)):
- Modules scanned from `~/.emacs.d/modules/` (built-in) and `~/.doom.d/modules/` (private)
- Organized by category (`:app`, `:lang`, `:tools`, `:editor`, `:ui`, etc.)
- Private modules can override built-in ones with same name

**Load Order** ([source](https://discourse.doomemacs.org/t/how-to-write-your-own-modules/86)):
1. Doom core loads
2. All modules' `packages.el` files evaluated
3. Packages installed/compiled (via `doom sync`)
4. All modules' `init.el` files executed
5. All packages loaded
6. All modules' `config.el` files executed
7. User's `$DOOMDIR/config.el` executed last

**Sync Command** ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org)):
- `doom sync` regenerates autoloads, installs/removes packages
- Run after changing `doom!` block or modifying packages.el
- Generates `~/.emacs.d/.local/autoloads.el`

### Lazy Loading with Autoload

**Autoload Pattern** ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org)):
- Place `;;;###autoload` cookie above function definitions
- `doom sync` scans and generates autoload stubs
- Functions load only when first called, not at startup
- Significant performance benefit for large configs

**Autoload Files** ([source](https://discourse.doomemacs.org/t/how-to-write-your-own-modules/86)):
- `autoload.el` in module root
- OR `autoload/*.el` for multiple files
- All functions auto-discovered with `;;;###autoload` cookie

**Example**:
```elisp
;;;###autoload
(defun my-module-do-something ()
  "This function lazy-loads when first called."
  (message "Module loaded!"))
```

### Module API Exposure with Autodef

**Autodef Concept** ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org)):
- Special autoloaded functions guaranteed to always be defined
- Become no-op macros if containing module disabled
- Zero-cost abstraction for optional module features
- Cookie: `;;;###autodef` instead of `;;;###autoload`

**Example** ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org)):
```elisp
;;;###autodef
(defun set-company-backend! (mode &rest backends)
  "Register BACKENDS for MODE."
  ...)

;; In user config - works whether :completion company enabled or not
(set-company-backend! 'python-mode '(company-anaconda))
```

**Discovery** ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org)):
- Browse autodefs with `M-x doom/help-autodefs` (SPC h d u)
- Module-exposed APIs discoverable and documented

### Configuration Macros

**`after!` Macro** ([source](https://dotdoom.rgoswami.me/config.html)):
- Expands to `eval-after-load`
- Defers configuration until package loaded
- Example: `(after! magit (setq magit-repository-directories '(("~/projects" . 2))))`

**`use-package!` Macro** ([source](https://discourse.doomemacs.org/t/how-to-write-your-own-modules/86)):
- Used in config.el for additional package configuration
- Works with packages declared in packages.el

**`setq!` Macro** ([source](https://github.com/hlissner/doom-emacs/issues/88)):
- Triggers defcustom setters (unlike plain setq)
- Use for variables with custom setters
- Example: `(setq! custom-variable value)`

### Module Categories ([source](https://github.com/doomemacs/doomemacs/blob/master/docs/modules.org))

- **:app** - Complex applications (load last before :config)
- **:checkers** - Syntax/spell checking
- **:completion** - Code completion frameworks
- **:config** - Configuration helpers
- **:editor** - Text manipulation
- **:emacs** - Built-in Emacs enhancements
- **:email** - Email clients
- **:input** - Input methods
- **:lang** - Language support
- **:os** - OS integration
- **:term** - Terminal emulators
- **:tools** - Development tools
- **:ui** - UI enhancements

### Inter-Module Dependencies

**Module Detection** ([source](https://discourse.doomemacs.org/t/how-to-write-your-own-modules/86)):
- Use `featurep!` to conditionally configure based on other modules
- Example: `(when (featurep! :completion company) (package! company-plugin))`

**Dependency Declaration** ([source](https://github.com/belak/doom-emacs/blob/develop/docs/getting_started.org)):
- Use `depend-on!` macro in packages.el
- Ensures dependency modules loaded first

## LazyVim Comparison

### Structure Differences

**LazyVim Directory Structure** ([source](https://lazy.folke.io/usage/structuring)):
```
~/.config/nvim/
├── init.lua
├── lua/
│   ├── config/
│   │   ├── autocmds.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua      # Plugin manager setup
│   │   └── options.lua
│   └── plugins/          # Auto-discovered specs
│       ├── init.lua
│       ├── editor.lua
│       ├── lsp.lua
│       └── *.lua         # All merged automatically
```

**Auto-Discovery** ([source](https://lazy.folke.io/usage/structuring)):
- All `*.lua` files in `plugins/` automatically merged
- Call `require("lazy").setup("plugins")` once
- No explicit require statements needed for plugin specs

**Spec Merging** ([source](https://lazy.folke.io/usage/structuring)):
- `opts`, `dependencies`, `cmd`, `event`, `ft`, `keys` merge with parent
- All other properties override parent spec
- Allows extending imported specs from LazyVim core

### Import System

**Module Imports** ([source](https://lazy.folke.io/usage/structuring)):
```lua
{
  "LazyVim/LazyVim",
  import = "lazyvim.plugins"  -- Import core plugins
}

{
  import = "lazyvim.plugins.extras.coding.copilot"  -- Import extras
}
```

**Plugin Categories** ([source](https://deepwiki.com/LazyVim/LazyVim/3.2-plugin-management)):
1. **Core Plugins** - Enabled by default
2. **Lazy Extras** - Optional, easy to enable
3. **Third-party** - User configured from scratch

## Detailed Analysis

### Doom's Architectural Strengths

1. **Clear Separation of Concerns**
   - packages.el: Pure dependency declarations
   - init.el: Early-stage setup
   - config.el: Main configuration logic
   - Prevents mixing concerns, easier to debug

2. **Performance-First Design**
   - Aggressive lazy-loading via autoload
   - Autodef ensures zero overhead for disabled modules
   - Compiled bytecode for all modules
   - Startup time typically under 1 second even with 100+ packages

3. **Declarative User Interface**
   - `doom!` block is simple, readable DSL
   - Flags provide fine-grained control
   - Users never edit module code directly
   - Clear contract between modules and users

4. **Discoverable Module APIs**
   - Autodef functions explicitly expose module capabilities
   - `doom/help-autodefs` provides documentation
   - Type hints and docstrings for all public functions
   - Reduces need to read module source

5. **Robust Module Isolation**
   - Modules can't accidentally interfere
   - Conditional loading via featurep! prevents conflicts
   - Private modules can override built-ins cleanly
   - Module flags scope configuration to specific features

### LazyVim's Architectural Strengths

1. **Extreme Simplicity**
   - Single lua file per plugin or feature group
   - No complex multi-file structure
   - Immediate evaluation, no separate phases

2. **Flexible Overriding**
   - Spec merging allows incremental customization
   - Can extend imported specs without copying
   - Property-level merge control (merge vs override)

3. **Import System**
   - Compose from multiple plugin collections
   - LazyVim core + extras + custom
   - Clear namespace separation

4. **Less Magic**
   - Straightforward Lua module system
   - Standard require() semantics
   - Easier to understand for newcomers

### Trade-offs

**Doom Advantages**:
- Better for large, complex configurations
- Superior performance through lazy loading
- Stronger module isolation and API contracts
- More sophisticated dependency management

**LazyVim Advantages**:
- Simpler mental model (one file = one concern)
- Less ceremony for small configs
- More "Lua-native" approach
- Easier to get started

## Applicable Patterns for WezTerm

### 1. Three-File Module Pattern
- `init.lua` - Early setup, feature flags
- `config.lua` - Main module logic
- `dependencies.lua` - External plugin/module requirements

### 2. Declarative User Configuration
```lua
-- wezterm.lua
return {
  modules = {
    ui = { "tabbar", "statusbar" },
    editor = { "keybindings", "search" },
    tools = { "multiplexer", "ssh" },
  },
  flags = {
    ui = { "rounded_corners", "transparent_bg" },
    editor = { "vim_mode" },
  }
}
```

### 3. Lazy Loading via Require
- Don't load modules until first use
- Use `package.loaded` checks to prevent duplicate loads
- Provide autoload-style stubs for expensive operations

### 4. Module API Exposure
- Each module exports table of functions
- Optional features return no-op functions when disabled
- Central registry of module APIs

### 5. Flag System
- Simple boolean or string flags
- Check flags in module code: `if config.flags.ui.transparent_bg then`
- Consistent naming convention (snake_case for WezTerm/Lua)

### 6. Module Discovery
- Scan `modules/` directory at startup
- Load based on user's enabled list
- Support both built-in and user-local modules

### 7. Configuration Hooks
- `before_load` - Early setup (like init.el)
- `on_load` - Main config (like config.el)
- `after_load` - Post-config hooks
- Allow modules to expose lifecycle hooks

## Sources

- [Doom Emacs modules.org - Module Documentation](https://github.com/doomemacs/doomemacs/blob/master/docs/modules.org)
- [Doom Emacs getting_started.org - Getting Started Guide](https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org)
- [How to write your own modules - Doom Discourse](https://discourse.doomemacs.org/t/how-to-write-your-own-modules/86)
- [Doom Emacs Documentation v21.12](https://docs.doomemacs.org/latest/)
- [My Doom Emacs configuration, with commentary](https://zzamboni.org/post/my-doom-emacs-configuration-with-commentary/)
- [Literate doom-emacs config](https://dotdoom.rgoswami.me/config.html)
- [Doom Emacs config by const.no](https://www.const.no/init/)
- [Doom Emacs FAQ](https://docs.doomemacs.org/latest/faq)
- [lazy.nvim - Structuring Your Plugins](https://lazy.folke.io/usage/structuring)
- [LazyVim Plugin Management](https://deepwiki.com/LazyVim/LazyVim/3.2-plugin-management)
- [Best practices for overriding settings in doom modules](https://github.com/hlissner/doom-emacs/issues/88)

## Confidence Level

**High** - Information gathered from official Doom Emacs documentation, GitHub repository, and multiple community sources with consistent patterns. LazyVim information comes from official documentation. Architectural analysis based on well-documented design patterns.

## Related Questions

- How does Doom handle module versioning and compatibility?
- What testing frameworks does Doom use for module tests?
- How does Doom's doctor.el diagnostic system work?
- What's the performance impact of autoload generation?
- How does Doom handle conflicts between module keybindings?
- How could WezTerm implement hot-reloading for module changes?
