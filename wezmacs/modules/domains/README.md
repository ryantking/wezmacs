# domains module

Quick domain management for SSH, Docker, and Kubernetes connections.

## Features

- **Domain Attach**: Quick fuzzy search to attach to SSH/Docker/Kubernetes domains
- **Domain Splits**: Open domains in vertical or horizontal splits
- **Auto-detection**: Automatically detect and manage domain types
- **Configurable Filters**: Choose which domain types to enable
- **Keybinding Customization**: Full control over keybindings

## Configuration

```lua
config = {
  devops = {
    domains = {
      attach_key = "t",               -- Key for domain attach
      attach_mod = "ALT|SHIFT",       -- Modifier for attach
      vsplit_key = "_",               -- Key for vertical split
      vsplit_mod = "CTRL|SHIFT|ALT",  -- Modifier for vsplit
      hsplit_key = "-",               -- Key for horizontal split
      hsplit_mod = "CTRL|ALT",        -- Modifier for hsplit
      ssh_ignore = true,              -- Ignore SSH domains
      docker_ignore = false,          -- Ignore Docker domains
      kubernetes_ignore = true,       -- Ignore Kubernetes domains
    }
  }
}
```

## Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `ALT+SHIFT+t` | Attach domain | Fuzzy search and attach to domain |
| `CTRL+SHIFT+ALT+_` | Vertical split | Open domain in vertical split |
| `CTRL+ALT+-` | Horizontal split | Open domain in horizontal split |

## External Dependencies

- **quick_domains plugin**: WezTerm plugin for domain management
  - Repository: https://github.com/DavidRR-F/quick_domains.wezterm
  - Auto-installed by WezTerm on first use

## Usage

**Attach to Domain**: Press `ALT+SHIFT+t` to open a fuzzy finder with available domains.
Select a domain to attach to it in a new tab or window.

**Split Domains**: Use the split keybindings to open domains in splits within the current tab.

## Domain Types

- **SSH**: Remote server connections via SSH
- **Docker**: Docker container connections
- **Kubernetes**: Kubernetes pod connections

Each domain type can be independently enabled/disabled via the configuration.
