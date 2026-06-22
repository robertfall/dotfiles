# Dotfiles

Cross-platform dotfiles for macOS and WSL (Windows Subsystem for Linux).

## Structure

```
.zshrc               # Shared zsh config (sources OS- and device-specific files)
.zshrc.macos         # macOS-specific config (Homebrew, 1Password agent, etc.)
.zshrc.linux         # Linux-specific config (shared by native Linux and WSL)
.zshrc.wsl           # WSL-specific config (Windows paths, pnpm, wezterm integration)
.zshrc.local.example # Template for ~/.zshrc.local (per-device, untracked)
.tmux.conf           # Tmux configuration
.gitconfig           # Git configuration
nvim/                # Neovim configuration (Lua-based, uses lazy.nvim)
wezterm/             # Wezterm terminal configuration
```

## Platform Detection

Config loads in layers: shared base -> OS-specific -> device-specific.

The main `.zshrc` auto-detects the OS and sources the appropriate config:
- `$OSTYPE == darwin*` -> sources `.zshrc.macos`
- `$OSTYPE == linux*` -> sources `.zshrc.linux` (and `.zshrc.wsl` when `$WSL_DISTRO_NAME` is set)

### Device-specific config

For settings that vary per *machine* rather than per OS (tools installed on only
some boxes, local paths), `.zshrc` sources `~/.zshrc.local` if it exists.
`~/.zshrc.local` is **not** tracked in dotfiles — copy `.zshrc.local.example` to
`~/.zshrc.local` on a given machine and uncomment what applies. Absence is a no-op.

## Key Tools

- **mise** - Runtime version manager (node, ruby, etc.)
- **antigen** - Zsh plugin manager (zsh-z, jq-zsh-plugin)
- **atuin** - Shell history sync
- **fzf** - Fuzzy finder
- **neovim** - Editor with lazy.nvim plugin management
- **wezterm** - Terminal emulator

## Installation

Files are symlinked to their expected locations:
- `.zshrc*` files -> `~/.zshrc*`
- `nvim/` -> `~/.config/nvim/`
- `wezterm/` -> `~/.config/wezterm/` (or appropriate location)

## Notes

- Don't mention Claude Code in commit messages
- Services (redis, mysql) can be started with `docker compose up -d` if needed
