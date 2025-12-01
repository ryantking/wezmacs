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

# Initialize ~/.config/wezmacs with user configuration
init:
    @if [ -d ~/.config/wezmacs ]; then \
        echo "~/.config/wezmacs already exists"; \
        echo "Remove it first with: rm -rf ~/.config/wezmacs"; \
        exit 1; \
    fi
    @echo "Initializing ~/.config/wezmacs..."
    @mkdir -p ~/.config/wezmacs/custom-modules
    @cp user/config.lua ~/.config/wezmacs/config.lua
    @echo "✓ Initialized ~/.config/wezmacs"
    @echo ""
    @echo "Next steps:"
    @echo "1. Edit ~/.config/wezmacs/config.lua to enable/configure modules"
    @echo "2. Reload WezTerm configuration (Cmd+Option+R on macOS)"

# Install WezMacs to ~/.config/wezterm
install:
    @if [ -d ~/.config/wezterm ]; then \
        if [ -f ~/.config/wezterm/wezterm.lua ]; then \
            echo "WezTerm config already exists at ~/.config/wezterm"; \
            echo "Backup your existing config and try again"; \
            exit 1; \
        fi \
    fi
    @echo "Installing WezMacs framework to ~/.config/wezterm..."
    @mkdir -p ~/.config/wezterm
    @cp -r wezmacs ~/.config/wezterm/
    @cp wezterm.lua ~/.config/wezterm/
    @mkdir -p ~/.config/wezmacs/custom-modules
    @echo "✓ WezMacs framework installed"
    @echo ""
    @echo "Next steps:"
    @echo "1. Run 'just init' to create ~/.config/wezmacs/config.lua"
    @echo "2. Edit ~/.config/wezmacs/config.lua to configure modules"
    @echo "3. Reload WezTerm (Cmd+Option+R on macOS)"

# Update existing WezMacs installation
update:
    @if [ ! -d ~/.config/wezterm/.git ]; then \
        echo "WezMacs not installed via git at ~/.config/wezterm"; \
        echo "Cannot auto-update. Please reinstall with 'just install'"; \
        exit 1; \
    fi
    @echo "Updating WezMacs framework..."
    @cd ~/.config/wezterm && git pull
    @echo "✓ Framework updated"
    @echo ""
    @echo "Your configuration at ~/.config/wezmacs/config.lua is unchanged"
    @echo "Reload WezTerm to apply updates (Cmd+Option+R)"

# Uninstall WezMacs
uninstall:
    @echo "⚠️  This will remove WezMacs from ~/.config/wezterm"
    @echo "Your configuration at ~/.config/wezmacs will NOT be deleted"
    @echo ""
    @if [ -d ~/.config/wezterm ]; then \
        rm -rf ~/.config/wezterm/wezmacs; \
        rm -f ~/.config/wezterm/wezterm.lua; \
        echo "✓ WezMacs removed from ~/.config/wezterm"; \
    fi
    @echo ""
    @echo "To restore your original wezterm.lua configuration, see your backups"

# Show installation status
status:
    @echo "WezMacs Installation Status"
    @echo "==========================="
    @echo ""
    @if [ -d ~/.config/wezterm ]; then \
        echo "✓ Framework installed at ~/.config/wezterm"; \
    else \
        echo "✗ Framework NOT installed"; \
    fi
    @if [ -d ~/.config/wezmacs ]; then \
        echo "✓ User config exists at ~/.config/wezmacs"; \
        echo "  - Main config: ~/.config/wezmacs/config.lua"; \
        if [ -d ~/.config/wezmacs/custom-modules ]; then \
            echo "  - Custom modules: ~/.config/wezmacs/custom-modules/"; \
        fi \
    else \
        echo "✗ User config directory NOT found"; \
    fi
    @echo ""
    @if [ -d ~/.config/wezterm ] && [ -d ~/.config/wezmacs ]; then \
        echo "Status: ✓ Ready to use!"; \
    else \
        echo "Status: Run 'just install' to set up"; \
    fi

# Test WezMacs with current branch's config
test:
    #!/bin/bash
    set -e

    # Create temporary test config directory
    TEST_CONFIG_DIR=$(mktemp -d)
    trap "rm -rf $TEST_CONFIG_DIR" EXIT

    # Copy framework files to temp location
    mkdir -p "$TEST_CONFIG_DIR/wezterm"
    cp -r wezmacs "$TEST_CONFIG_DIR/wezterm/"
    cp wezterm.lua "$TEST_CONFIG_DIR/wezterm/"

    # Create test user config directory and copy templates
    mkdir -p "$TEST_CONFIG_DIR/wezmacs/custom-modules"
    cp user/modules.lua "$TEST_CONFIG_DIR/wezmacs/modules.lua"
    cp user/config.lua "$TEST_CONFIG_DIR/wezmacs/config.lua"

    echo "Testing WezMacs with current branch configuration..."
    echo "Config directory: $TEST_CONFIG_DIR"
    echo "Press Ctrl+D or type 'exit' to close"
    echo ""

    # Run wezterm with test config
    WEZTERM_CONFIG_DIR="$TEST_CONFIG_DIR/wezterm" \
    XDG_CONFIG_HOME="$TEST_CONFIG_DIR" \
    wezterm

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
    @echo "  • See wezmacs/modules/*/README.md for each module"
    @echo ""
    @echo "Examples:"
    @echo "  • examples/minimal.lua - Minimal configuration"
    @echo "  • examples/full.lua - All modules enabled"
    @echo "  • examples/advanced.lua - Custom modules and overrides"
    @echo ""
    @echo "To view documentation, try:"
    @echo "  cat README.md"
    @echo "  cat FRAMEWORK.md"

# Development server (watch and lint)
watch:
    @echo "Watching for changes..."
    @while true; do \
        inotifywait -r -e modify wezmacs/ examples/ user/ 2>/dev/null || sleep 2; \
        clear; \
        just lint; \
    done

# Create a new module from template
new-module MODULE_NAME:
    #!/bin/bash
    set -e

    MODULE_DIR="wezmacs/modules/{{MODULE_NAME}}"

    if [ -d "$MODULE_DIR" ]; then
        echo "Error: Module already exists at $MODULE_DIR"
        exit 1
    fi

    echo "Creating new module: {{MODULE_NAME}}"
    mkdir -p "$MODULE_DIR"

    # Copy template
    cp wezmacs/templates/module.lua "$MODULE_DIR/init.lua"

    # Create README
    cat > "$MODULE_DIR/README.md" << 'EOF'
# {{MODULE_NAME}} module

Brief description of what this module does.

## Features

- Feature 1
- Feature 2

## Configuration

```lua
flags = {
  category = {
    {{MODULE_NAME}} = {}
  }
}
```

## External Dependencies

None

## Keybindings

None

## Related Modules

None
EOF

    echo "✓ Module created at $MODULE_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Edit $MODULE_DIR/init.lua to implement your module"
    echo "2. Update $MODULE_DIR/README.md with documentation"
    echo "3. Test by enabling in ~/.config/wezmacs/config.lua"

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
