# Research: LazyVim Architecture and Configuration System
Date: 2025-12-06
Focus: Configuration structure, module system, lazy loading, plugin specs, keybindings, shared state
Agent: researcher

## Summary

LazyVim is a Neovim configuration framework built on lazy.nvim that provides a modular, extensible plugin architecture. It uses a layered configuration system with automatic file loading, deep merging of plugin options, and a comprehensive utility module for sharing state between plugins. The "extras" system enables optional feature modules that can be toggled via UI or imports.

## Key Findings

- **Directory Structure**: LazyVim uses `~/.config/nvim/lua/config/` for core settings and `~/.config/nvim/lua/plugins/` for plugin specs, with automatic file loading ([LazyVim Configuration](https://www.lazyvim.org/configuration))
- **Plugin Spec Format**: Specs support `opts`, `keys`, `cmd`, `event`, `ft`, `dependencies`, `enabled`, `cond`, `priority`, and `config` fields with automatic merging ([lazy.nvim Spec](https://lazy.folke.io/spec))
- **Lazy Loading**: Five trigger patterns - `event`, `cmd`, `ft`, `keys`, and module `require()` - plus `VeryLazy` event for non-critical plugins ([Lazy Loading](https://lazy.folke.io/spec/lazy_loading))
- **Extras System**: Pre-configured feature modules imported via `{ import = "lazyvim.plugins.extras.lang.typescript" }` or `:LazyExtras` UI ([LazyVim Plugins](https://www.lazyvim.org/configuration/plugins))
- **Shared Utilities**: `LazyVim.has()`, `LazyVim.opts()`, `LazyVim.pick()`, `LazyVim.extend()` provide cross-plugin coordination ([LazyVim Util](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/init.lua))
- **Keybinding Management**: Centralized via which-key.nvim with hierarchical groups and discoverable menus ([LazyVim Keymaps](https://www.lazyvim.org/configuration/keymaps))

## Detailed Analysis

### Configuration File Structure

LazyVim organizes configuration in a predictable directory layout:

```
~/.config/nvim/
├── init.lua                    # Entry point (bootstraps lazy.nvim)
├── lua/
│   ├── config/
│   │   ├── autocmds.lua       # Autocommands
│   │   ├── keymaps.lua        # Global keybindings
│   │   ├── lazy.lua           # lazy.nvim setup and imports
│   │   └── options.lua        # Neovim options (vim.opt.*)
│   └── plugins/
│       ├── *.lua              # User plugin specifications
│       └── (auto-loaded)      # All .lua files merged automatically
└── lazyvim.json               # Enabled extras state file
```

Files under `config/` are automatically loaded at appropriate times - no manual `require()` needed. The `plugins/` directory uses lazy.nvim's auto-discovery: any `.lua` file returning a table of specs is merged into the main configuration.

### Plugin Spec Format

The plugin spec is a Lua table describing how to load and configure a plugin:

```lua
return {
  -- Minimal spec - just the GitHub short URL
  { "author/plugin-name" },

  -- Full spec with all common options
  {
    "author/plugin-name",

    -- Loading configuration
    lazy = true,                    -- Don't load on startup
    priority = 1000,                -- Load order (higher = earlier, for colorschemes)
    enabled = true,                 -- Include in config (can be function)
    cond = true,                    -- Like enabled but doesn't uninstall when false

    -- Lazy-loading triggers (any of these makes lazy=true implicit)
    event = "BufEnter",             -- Load on Neovim event
    cmd = "MyCommand",              -- Load when command executed
    ft = "lua",                     -- Load for filetype
    keys = {                        -- Load on keymap
      { "<leader>x", "<cmd>Action<cr>", desc = "Do Action" },
    },

    -- Plugin configuration
    opts = {                        -- Passed to setup() - MERGED with parent specs
      option1 = "value",
    },
    -- OR use function for dynamic opts (receives plugin and parent opts)
    opts = function(_, opts)
      opts.option1 = "modified"
      return opts
    end,

    config = function(_, opts)      -- Custom setup (default: require(MAIN).setup(opts))
      require("plugin").setup(opts)
    end,

    -- Dependencies
    dependencies = {
      "other/plugin",
      { "another/plugin", opts = {} },
    },

    -- Initialization (runs during startup, before plugin loads)
    init = function()
      vim.g.plugin_setting = true
    end,
  },
}
```

**Merge Behavior**: When the same plugin appears in multiple specs, lazy.nvim merges them:
- `opts`, `dependencies`, `cmd`, `event`, `ft`, `keys` are **merged/extended**
- Other properties **override** the parent spec
- Function `opts` replaces rather than merges (receives parent opts as second arg)

### Lazy Loading Patterns

LazyVim leverages five lazy-loading triggers:

```lua
-- 1. EVENT-BASED: Load on Neovim events
{ "plugin", event = "BufEnter" }
{ "plugin", event = { "BufReadPre", "BufNewFile" } }
{ "plugin", event = "BufEnter *.lua" }  -- With pattern
{ "plugin", event = "VeryLazy" }        -- After startup (common for UI)

-- 2. COMMAND-BASED: Load when command executed
{ "plugin", cmd = "MyCommand" }
{ "plugin", cmd = { "CmdA", "CmdB" } }

-- 3. FILETYPE-BASED: Load for specific filetypes
{ "plugin", ft = "lua" }
{ "plugin", ft = { "markdown", "help" } }

-- 4. KEY-BASED: Load on keymap trigger
{ "plugin", keys = "<leader>f" }
{ "plugin", keys = {
  { "<leader>ff", "<cmd>Find<cr>", desc = "Find Files" },
  { "<leader>fg", mode = { "n", "v" }, desc = "Grep" },
}}

-- 5. MODULE-BASED: Automatic on require()
-- If lazy=true and another plugin does require("plugin"), it loads automatically
{ "plugin", lazy = true }
```

**VeryLazy Pattern**: For plugins not needed immediately but should load soon:
```lua
{ "stevearc/dressing.nvim", event = "VeryLazy" }
```

### Extras System (Modular Features)

LazyVim's "extras" are pre-configured feature bundles that can be enabled/disabled:

```lua
-- In lua/config/lazy.lua, import extras
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Enable specific extras
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.ui.mini-starter" },
    { import = "lazyvim.plugins.extras.editor.harpoon2" },
    -- User plugins
    { import = "plugins" },
  },
})
```

**Extras Categories** (from LazyVim repo):
- `ai/` - AI assistants (copilot, codeium)
- `coding/` - Code manipulation tools
- `dap/` - Debug adapter protocol
- `editor/` - Editor enhancements (harpoon, telescope)
- `formatting/` - Code formatters
- `lang/` - Language-specific configs (typescript, python, rust, go)
- `linting/` - Linters
- `lsp/` - LSP configurations
- `test/` - Test frameworks
- `ui/` - UI enhancements
- `util/` - Utilities

**`:LazyExtras` UI**: Interactive toggle for extras, persisted to `lazyvim.json`:
```json
{
  "extras": [
    "lazyvim.plugins.extras.lang.typescript",
    "lazyvim.plugins.extras.editor.harpoon2"
  ]
}
```

### Keybinding Management

LazyVim uses which-key.nvim for discoverable, hierarchical keybindings:

**Global Keymaps** (`lua/config/keymaps.lua`):
```lua
-- Direct vim.keymap.set
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })

-- Delete LazyVim default
vim.keymap.del("n", "<leader>wd")
```

**Plugin Keymaps** (in spec):
```lua
{
  "plugin-name",
  keys = {
    -- Simple mapping
    { "<leader>cs", "<cmd>Action<cr>", desc = "Do Action" },
    -- With mode
    { "<leader>cs", mode = { "n", "v" }, desc = "Do Action" },
    -- Function RHS
    { "<leader>cs", function() require("plugin").action() end, desc = "Action" },
    -- Disable a keymap
    { "<leader>cs", false },
  },
}
```

**Which-Key Groups**: LazyVim pre-defines leader key groups:
- `<leader>c` - Code
- `<leader>d` - Debug
- `<leader>f` - File/Find
- `<leader>g` - Git
- `<leader>s` - Search
- `<leader>u` - UI
- `<leader>x` - Diagnostics

### Shared State and Utilities

LazyVim provides a utility module for cross-plugin coordination:

```lua
-- Check if plugin is available
if LazyVim.has("trouble.nvim") then
  require("trouble").open()
end

-- Check if extra is enabled
if LazyVim.has_extra("formatting.prettier") then
  opts.formatters_by_ft.svelte = { "prettier" }
end

-- Get plugin options (resolved)
local telescope_opts = LazyVim.opts("telescope.nvim")

-- Extend nested tables safely (dot notation)
LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
  { name = "@vue/typescript-plugin", ... }
})

-- Picker abstraction (works with telescope/fzf/snacks)
LazyVim.pick.open("files")
LazyVim.pick("grep", { cwd = vim.fn.getcwd() })

-- Execute on plugin load
LazyVim.on_load("nvim-lspconfig", function()
  -- Configure after lspconfig loads
end)

-- LSP utilities
LazyVim.lsp.on_attach(function(client, buffer)
  -- Setup keymaps when LSP attaches
end)

-- Safe keymap (won't error if mapping exists)
LazyVim.safe_keymap_set("n", "<leader>x", "<cmd>Action<cr>")

-- Get Mason package path
local path = LazyVim.get_pkg_path("vue-language-server", "/node_modules/@vue/language-server")
```

**Lazy-loaded Submodules**: Accessed via metatable `__index`:
- `LazyVim.lsp` - LSP helpers
- `LazyVim.format` - Formatting
- `LazyVim.pick` - Picker abstraction
- `LazyVim.terminal` - Terminal management
- `LazyVim.root` - Project root detection
- `LazyVim.cmp` - Completion helpers

### User Overrides Pattern

**Override plugin options** (merged):
```lua
{
  "folke/trouble.nvim",
  opts = { use_diagnostic_signs = true },
}
```

**Override with function** (full control):
```lua
{
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    -- Modify the existing opts
    table.insert(opts.sources, { name = "emoji" })
    -- Or return completely new opts
    return opts
  end,
}
```

**Extend list-based options**:
```lua
{
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    vim.list_extend(opts.ensure_installed, {
      "tsx", "typescript", "vue"
    })
  end,
}
```

**Disable a plugin**:
```lua
{ "folke/trouble.nvim", enabled = false }
```

**Replace a keymap**:
```lua
{
  "neo-tree.nvim",
  keys = {
    { "<leader>e", false },  -- Disable default
    { "<leader>fe", "<cmd>Neotree<cr>", desc = "Explorer" },
  },
}
```

## Applicable Patterns for WezMacs

1. **Directory Convention**: Mirror `lua/config/` and `lua/plugins/` structure with `wezmacs/config/` and `wezmacs/modules/`

2. **Spec-Based Module Definition**: Each WezMacs module could return a spec table with:
   - `opts` - Module configuration
   - `keys` - Keybindings to register
   - `dependencies` - Other modules required
   - `enabled` - Conditional loading

3. **Deep Merge for opts**: Implement `vim.tbl_deep_extend`-style merging for module options

4. **Utility Module**: Create `wezmacs.util` with:
   - `has(module)` - Check if module enabled
   - `opts(module)` - Get resolved module options
   - `extend(tbl, path, value)` - Deep extend helper
   - `on_load(module, fn)` - Hook into module loading

5. **Extras Pattern**: Support optional feature bundles via imports:
   ```lua
   { import = "wezmacs.modules.extras.editor.lazygit" }
   ```

6. **Keybinding Groups**: Pre-define leader key groups with which-key-style discoverability

7. **Lazy Loading Analogs**: For WezTerm:
   - `event` -> WezTerm events (e.g., `window-config-reloaded`)
   - `cmd` -> On-demand action loading
   - `keys` -> Keybinding-triggered module activation

## Sources

- [LazyVim Configuration](https://www.lazyvim.org/configuration)
- [LazyVim Plugins](https://www.lazyvim.org/configuration/plugins)
- [LazyVim Keymaps](https://www.lazyvim.org/configuration/keymaps)
- [LazyVim Configuration Examples](https://www.lazyvim.org/configuration/examples)
- [lazy.nvim Plugin Spec](https://lazy.folke.io/spec)
- [lazy.nvim Lazy Loading](https://lazy.folke.io/spec/lazy_loading)
- [lazy.nvim Structuring Plugins](https://lazy.folke.io/usage/structuring)
- [LazyVim GitHub Repository](https://github.com/LazyVim/LazyVim)
- [LazyVim Util Module](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/init.lua)
- [LazyVim Starter Example](https://github.com/LazyVim/starter/blob/main/lua/plugins/example.lua)
- [lazy.nvim GitHub Repository](https://github.com/folke/lazy.nvim)
- [Spec Merging Discussion](https://github.com/folke/lazy.nvim/discussions/1706)

## Confidence Level

**High** - Multiple authoritative sources (official documentation, GitHub repos) with consistent information. The patterns are well-documented and widely used in the Neovim community.

## Related Questions

- How does LazyVim handle plugin update notifications and version locking?
- What is the performance impact of lazy loading vs eager loading for small plugins?
- How do LazyVim users typically organize large custom configurations?
- What patterns exist for sharing configuration across multiple machines?
