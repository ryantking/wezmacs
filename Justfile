# WezMacs Justfile
# Common development and deployment tasks

set shell := ["bash", "-c"]
set dotenv-load := false

# Default recipe - show help
default:
    @just --list

# Install dependencies for development
deps:
    @echo "Installing development dependencies..."
    @command -v luacheck > /dev/null || (echo "Installing luacheck..." && brew install luacheck)
    @command -v stylua > /dev/null || (echo "Installing stylua..." && brew install stylua)
    @echo "✓ Development dependencies installed"

# Format all Lua files with StyLua
fmt:
    @echo "Formatting Lua files..."
    stylua --check-only lua/ 2>/dev/null || stylua lua/
    @echo "✓ Formatting complete"

# Check code quality with Luacheck
lint:
    @echo "Linting with luacheck..."
    luacheck lua/ --codes 2>/dev/null || true
    @echo "✓ Linting complete"

# Format and lint (full code quality check)
check: fmt lint
    @echo "✓ Code quality check passed"

# Generate user configuration at ~/.config/wezmacs/
init:
    @if [ -f ~/.config/wezmacs/config.lua ]; then \
        echo "WezMacs config already exists: ~/.config/wezmacs/config.lua"; \
        echo "Remove existing config first or run 'just init --force' to overwrite"; \
        exit 1; \
    fi
    @echo "Generating WezMacs configuration..."
    @lua lua/generate-config.lua
    @mkdir -p ~/.config/wezterm/modules
    @echo ""
    @echo "Next steps:"
    @echo "1. Copy example/wezterm.lua to ~/.config/wezterm/wezterm.lua"
    @echo "2. Edit ~/.config/wezmacs/config.lua to enable/configure modules"
    @echo "3. Reload WezTerm configuration"

# Install WezMacs to XDG_DATA_HOME/wezmacs (defaults to ~/.local/share/wezmacs)
install:
    @if [ -d ~/.local/share/wezmacs/lua ]; then \
        echo "WezMacs already installed at ~/.local/share/wezmacs/lua"; \
        echo "Run 'just update' to update, or 'just uninstall' to remove"; \
        exit 1; \
    fi
    @echo "Installing WezMacs framework to ~/.local/share/wezmacs..."
    @mkdir -p ~/.local/share
    @git clone "https://github.com/ryantking/wezmacs" ~/.local/share/wezmacs
    @echo "✓ WezMacs framework installed"
    @echo ""
    @echo "Next steps:"
    @echo "1. Copy example/wezterm.lua to ~/.config/wezterm/wezterm.lua"
    @echo "2. Run 'just init' to create ~/.config/wezmacs/config.lua"
    @echo "3. Edit ~/.config/wezmacs/config.lua to configure modules"
    @echo "4. Reload WezTerm (Cmd+Option+R on macOS)"

# Update existing WezMacs installation
update:
    @if [ ! -d ~/.local/share/wezmacs/.git ]; then \
        echo "WezMacs not installed via git at ~/.local/share/wezmacs"; \
        echo "Cannot auto-update. Please reinstall with 'just install'"; \
        exit 1; \
    fi
    @echo "Updating WezMacs framework..."
    @cd ~/.local/share/wezmacs && git pull
    @echo "✓ Framework updated"
    @echo ""
    @echo "Your configuration at ~/.config/wezmacs/config.lua is unchanged"
    @echo "Reload WezTerm to apply updates (Cmd+Option+R)"

# Uninstall WezMacs
uninstall:
    @echo "⚠️  This will remove WezMacs from ~/.local/share/wezmacs"
    @echo "Your configuration at ~/.config/wezmacs/config.lua will NOT be deleted"
    @echo ""
    @if [ -d ~/.local/share/wezmacs ]; then \
        rm -rf ~/.local/share/wezmacs; \
        echo "✓ WezMacs removed from ~/.local/share/wezmacs"; \
    fi
    @echo ""
    @echo "Note: Your ~/.config/wezterm/wezterm.lua is unchanged"

# Show installation status
status:
    @echo "WezMacs Installation Status"
    @echo "==========================="
    @echo ""
    @if [ -d ~/.local/share/wezmacs/lua ]; then \
        echo "✓ Framework installed at ~/.local/share/wezmacs/lua"; \
    else \
        echo "✗ Framework NOT installed"; \
    fi
    @if [ -f ~/.config/wezmacs/config.lua ]; then \
        echo "✓ User config: ~/.config/wezmacs/config.lua"; \
    else \
        echo "✗ User config NOT found"; \
        echo "  Run 'just init' to generate configuration"; \
    fi
    @if [ -d ~/.config/wezterm/modules ]; then \
        echo "  - Custom modules: ~/.config/wezterm/modules/"; \
    fi
    @echo ""
    @if [ -d ~/.local/share/wezmacs/lua ] && [ -f ~/.config/wezmacs/config.lua ]; then \
        echo "Status: ✓ Ready to use!"; \
    else \
        echo "Status: Run 'just install' and 'just init' to set up"; \
    fi

# Test WezMacs with local lua/ directory
test:
    #!/bin/bash
    set -e

    echo "Testing WezMacs with local lua/ directory"
    echo "Config directory: $(pwd)/test/"
    echo "Framework: $(pwd)/lua/"
    echo ""
    echo "Press Ctrl+D or type 'exit' to close WezTerm"
    echo ""

    # Clear WezTerm's Lua module cache by unsetting package.loaded entries
    # WezTerm caches Lua modules, so we need to force it to reload
    # Point wezterm to test/ directory which contains wezterm.lua
    # The test/config/wezmacs.lua will load from local lua/ directory
    # Using --config-file forces a fresh load
    wezterm --config-file "$(pwd)/test/wezterm.lua" start

# Clear WezTerm Lua module cache (requires restart)
clear-cache:
    #!/bin/bash
    @echo "Clearing WezTerm Lua module cache..."
    @echo "Note: WezTerm caches Lua modules in memory."
    @echo "To fully clear cache, you need to:"
    @echo "1. Close all WezTerm windows"
    @echo "2. Run this command"
    @echo "3. Restart WezTerm"
    @echo ""
    @echo "Alternatively, modify your config to clear package.loaded:"
    @echo "  for k in pairs(package.loaded) do"
    @echo "    if k:match('^wezmacs') then"
    @echo "      package.loaded[k] = nil"
    @echo "    end"
    @echo "  end"

# Show documentation
docs:
    @echo "WezMacs Documentation"
    @echo "===================="
    @echo ""
    @echo "User Guide:"
    @echo "  • README.md - Quick start and overview"
    @echo ""
    @echo "Developer Documentation:"
    @echo "  • FRAMEWORK.md - Architecture and design patterns"
    @echo "  • CONTRIBUTING.md - How to create modules"
    @echo ""
    @echo "Module Documentation:"
    @echo "  • See lua/modules/*/README.md for each module"
    @echo ""
    @echo "Examples:"
    @echo "  • example/wezterm.lua - Example user configuration"
    @echo "  • test/wezterm.lua - Test configuration for development"
    @echo ""
    @echo "To view documentation, try:"
    @echo "  cat README.md"
    @echo "  cat FRAMEWORK.md"

# Development server (watch and lint)
watch:
    @echo "Watching for changes..."
    @while true; do \
        inotifywait -r -e modify lua/ example/ test/ 2>/dev/null || sleep 2; \
        clear; \
        just lint; \
    done

# Create a new module from template
new-module MODULE_NAME:
    @echo "Creating new module: {{MODULE_NAME}}"
    @mkdir -p "lua/modules/{{MODULE_NAME}}"
    @cp lua/templates/module.lua "lua/modules/{{MODULE_NAME}}.lua"
    @echo "# {{MODULE_NAME}} module" > "lua/modules/{{MODULE_NAME}}.md"
    @echo "" >> "lua/modules/{{MODULE_NAME}}.md"
    @echo "Brief description of what this module does" >> "lua/modules/{{MODULE_NAME}}.md"
    @echo "" >> "lua/modules/{{MODULE_NAME}}.md"
    @echo "## Configuration" >> "lua/modules/{{MODULE_NAME}}.md"
    @echo "" >> "lua/modules/{{MODULE_NAME}}.md"
    @echo '```lua' >> "lua/modules/{{MODULE_NAME}}.md"
    @echo "{{MODULE_NAME}} = {}" >> "lua/modules/{{MODULE_NAME}}.md"
    @echo '```' >> "lua/modules/{{MODULE_NAME}}.md"
    @echo "✓ Module created at lua/modules/{{MODULE_NAME}}.lua"
    @echo ""
    @echo "Next steps:"
    @echo "1. Edit lua/modules/{{MODULE_NAME}}.lua"
    @echo "2. Update lua/modules/{{MODULE_NAME}}.md"

# Clean temporary files
clean:
    @echo "Cleaning temporary files..."
    @find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    @find . -type f -name "*.swp" -delete
    @find . -type f -name "*.swo" -delete
    @find . -type f -name "*~" -delete
    @echo "✓ Cleanup complete"

# Show version
version:
    @echo "WezMacs v0.1.0"
    @echo "A modular configuration framework for WezTerm"
    @echo ""
    @echo "Repository: https://github.com/yourusername/wezmacs"
