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

Run `./install.sh` to create or refresh all symlinks. It is re-runnable
(idempotent): links already pointing at the repo are left untouched, and any
target that exists as a real file or a wrong symlink is moved to
`<target>.bak-<timestamp>` before relinking. Use `./install.sh --dry-run` to
preview. The script detects the OS and links the right set:

- Common: `.zshrc`, `.tmux.conf`, `.gitconfig`, `.secrets`, `nvim/` ->
  `~/.config/nvim`, `ghostty/` -> `~/.config/ghostty`, `atuin/config.toml` ->
  `~/.config/atuin/config.toml` (linked *into* the live dir, which holds
  atuin's db/key/session — the dir itself is never replaced)
- macOS: `.zshrc.macos`, `wezterm/wezterm.lua` -> `~/.wezterm.lua`
- Linux/WSL: `.zshrc.linux`, `wezterm/wezterm.lua` ->
  `~/.config/wezterm/wezterm.lua`, plus `.zshrc.wsl` on WSL
- Linux opt-in (`./install.sh --hyprland`): `hypr/`, `waybar/`, `mako/` ->
  their matching directories under `~/.config`, plus
  `xdg-desktop-portal/hyprland-portals.conf` -> matching path under
  `~/.config/xdg-desktop-portal/` (routes the Settings/appearance portal
  interface to xdg-desktop-portal-gtk instead of xdg-desktop-portal-gnome,
  since there's no GNOME Shell to back the gnome portal backend). Without
  this flag, those targets are left untouched even when Hyprland is
  installed.
- `hypr/hyprland-uwsm.desktop` is tracked here as the source of truth but
  **not** symlinked by `install.sh` (it never uses sudo by design). It has to
  be copied into a root-owned path by hand:
  `sudo tee /usr/local/share/wayland-sessions/hyprland-uwsm.desktop < hypr/hyprland-uwsm.desktop`.
  This adds a second "Hyprland (uwsm)" entry in GDM's session list without
  touching the package-owned `/usr/share/wayland-sessions/hyprland.desktop`,
  which stays as a fallback if the uwsm-wrapped session ever fails to start.
  uwsm is required for this entry (installed here from the `solopasha/hyprland`
  COPR, restricted to `includepkgs=uwsm` so it can never touch the Hyprland
  package itself, which comes from a different COPR).

## Notes

- Don't mention Claude Code in commit messages
- Services (redis, mysql) can be started with `docker compose up -d` if needed
