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
    stylua --check-only wezmacs/ 2>/dev/null || stylua wezmacs/
    @echo "✓ Formatting complete"

# Check code quality with Luacheck
lint:
    @echo "Linting with luacheck..."
    luacheck wezmacs/ --codes 2>/dev/null || true
    @echo "✓ Linting complete"

# Format and lint (full code quality check)
check: fmt lint
    @echo "✓ Code quality check passed"

# Generate user configuration at ~/.config/wezmacs/
init:
    @if [ -f ~/.config/wezmacs/modules.lua ]; then \
        echo "WezMacs config already exists: ~/.config/wezmacs/modules.lua"; \
        echo "Remove existing config first or run 'just init --force' to overwrite"; \
        exit 1; \
    fi
    @echo "Generating WezMacs configuration..."
    @lua wezmacs/generate-config.lua
    @mkdir -p ~/.config/wezterm/modules
    @echo ""
    @echo "Next steps:"
    @echo "1. Copy example/wezterm.lua to ~/.config/wezterm/wezterm.lua"
    @echo "2. Edit ~/.config/wezmacs/modules.lua to enable/configure modules"
    @echo "3. Reload WezTerm configuration"

# Install WezMacs to ~/.config/wezterm/wezmacs
install:
    @if [ -d ~/.config/wezterm/wezmacs ]; then \
        echo "WezMacs already installed at ~/.config/wezterm/wezmacs"; \
        echo "Run 'just update' to update, or 'just uninstall' to remove"; \
        exit 1; \
    fi
    @echo "Installing WezMacs framework to ~/.config/wezterm/wezmacs..."
    @mkdir -p ~/.config/wezterm
    @git clone "https://github.com/ryantking/wezmacs" ~/.config/wezterm/wezmacs
    @echo "✓ WezMacs framework installed"
    @echo ""
    @echo "Next steps:"
    @echo "1. Copy example/wezterm.lua to ~/.config/wezterm/wezterm.lua"
    @echo "2. Run 'just init' to create ~/.config/wezmacs/modules.lua"
    @echo "3. Edit ~/.config/wezmacs/modules.lua to configure modules"
    @echo "4. Reload WezTerm (Cmd+Option+R on macOS)"

# Update existing WezMacs installation
update:
    @if [ ! -d ~/.config/wezterm/wezmacs/.git ]; then \
        echo "WezMacs not installed via git at ~/.config/wezterm/wezmacs"; \
        echo "Cannot auto-update. Please reinstall with 'just install'"; \
        exit 1; \
    fi
    @echo "Updating WezMacs framework..."
    @cd ~/.config/wezterm/wezmacs && git pull
    @echo "✓ Framework updated"
    @echo ""
    @echo "Your configuration at ~/.config/wezmacs/modules.lua is unchanged"
    @echo "Reload WezTerm to apply updates (Cmd+Option+R)"

# Uninstall WezMacs
uninstall:
    @echo "⚠️  This will remove WezMacs from ~/.config/wezterm/wezmacs"
    @echo "Your configuration at ~/.config/wezmacs/modules.lua will NOT be deleted"
    @echo ""
    @if [ -d ~/.config/wezterm/wezmacs ]; then \
        rm -rf ~/.config/wezterm/wezmacs; \
        echo "✓ WezMacs removed from ~/.config/wezterm/wezmacs"; \
    fi
    @echo ""
    @echo "Note: Your ~/.config/wezterm/wezterm.lua is unchanged"

# Show installation status
status:
    @echo "WezMacs Installation Status"
    @echo "==========================="
    @echo ""
    @if [ -d ~/.config/wezterm/wezmacs ]; then \
        echo "✓ Framework installed at ~/.config/wezterm/wezmacs"; \
    else \
        echo "✗ Framework NOT installed"; \
    fi
    @if [ -f ~/.config/wezmacs/modules.lua ]; then \
        echo "✓ User config: ~/.config/wezmacs/modules.lua"; \
    else \
        echo "✗ User config NOT found"; \
        echo "  Run 'just init' to generate configuration"; \
    fi
    @if [ -d ~/.config/wezterm/modules ]; then \
        echo "  - Custom modules: ~/.config/wezterm/modules/"; \
    fi
    @echo ""
    @if [ -d ~/.config/wezterm/wezmacs ] && [ -f ~/.config/wezmacs/modules.lua ]; then \
        echo "Status: ✓ Ready to use!"; \
    else \
        echo "Status: Run 'just install' and 'just init' to set up"; \
    fi

# Test WezMacs with test/ directory
test:
    #!/usr/bin/env bash
    export WEZTERM_CONFIG_FILE="$PWD/wezterm.lua"
    export WEZMACSDIR=$PWD/test
    wezterm start

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
    @echo "Repository: https://github.com/ryantking/wezmacs"
