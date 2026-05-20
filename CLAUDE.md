# Dotfiles

Cross-platform dotfiles for macOS and WSL (Windows Subsystem for Linux).

## Structure

```
.zshrc              # Shared zsh config (sources platform-specific files)
.zshrc.macos        # macOS-specific config (Homebrew, 1Password agent, etc.)
.zshrc.wsl          # WSL-specific config (Windows paths, pnpm, wezterm integration)
.tmux.conf          # Tmux configuration
.gitconfig          # Git configuration
nvim/               # Neovim configuration (Lua-based, uses lazy.nvim)
wezterm/            # Wezterm terminal configuration
```

## Platform Detection

The main `.zshrc` auto-detects the OS and sources the appropriate config:
- `$OSTYPE == darwin*` -> sources `.zshrc.macos`
- `$OSTYPE == linux*` -> sources `.zshrc.wsl`

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
