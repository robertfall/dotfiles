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
- **zinit** - Zsh plugin manager (jq-zsh-plugin)
- **zoxide** - Smart `cd` / directory jumper (also what yazi's `Z` jump shells out to)
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
- Linux opt-in (`./install.sh --hyprland`): `hypr/`, `waybar/`, `mako/`,
  `fuzzel/`, `swappy/` -> their matching directories under `~/.config`, plus
  `xdg-desktop-portal/hyprland-portals.conf` -> matching path under
  `~/.config/xdg-desktop-portal/` (routes the Settings/appearance portal
  interface to xdg-desktop-portal-gtk instead of xdg-desktop-portal-gnome,
  since there's no GNOME Shell to back the gnome portal backend), plus
  `anydesk/anydesk.desktop` -> `~/.local/share/applications/` and
  `anydesk/anydesk_global_tray.desktop` -> `~/.config/autostart/`
  (same-filename overrides that add `GDK_BACKEND=x11`; AnyDesk breaks as a
  native Wayland client), plus `hypr/keybinds.desktop` ->
  `~/.local/share/applications/` (a "Keybindings" launcher entry that opens
  the Super+? keybind help). Without this flag, those targets are left
  untouched even when Hyprland is installed.
- `hypr/hyprland-managed.desktop`, `hypr/hyprland-plain-hidden.desktop`, and
  `hypr/hyprland-uwsm-managed-hidden.desktop` are tracked here as the source
  of truth but **not** symlinked by `install.sh` (it never uses sudo by
  design). Copy them into root-owned paths by hand:
  ```
  sudo tee /usr/local/share/wayland-sessions/hyprland-managed.desktop < hypr/hyprland-managed.desktop
  sudo tee /usr/local/share/wayland-sessions/hyprland.desktop         < hypr/hyprland-plain-hidden.desktop
  sudo tee /usr/local/share/wayland-sessions/hyprland-uwsm.desktop    < hypr/hyprland-uwsm-managed-hidden.desktop
  ```
  The first adds the one visible "Hyprland (uwsm)" entry, launching Hyprland
  through uwsm directly (`uwsm start -N Hyprland -D Hyprland -e --
  /usr/bin/start-hyprland`, hardcoding the compositor path rather than
  referencing the `hyprland.desktop` ID — see below for why) — this gives it
  proper systemd session integration (see `hypr/hyprland.conf`'s AUTOSTART
  comments — this is what makes `graphical-session.target`, and therefore the
  portal, actually work). The second and third **mask** two entries that
  would otherwise also show up in GDM: the package-owned plain
  `/usr/share/wayland-sessions/hyprland.desktop`, and the Hyprland package's
  *own* uwsm-wrapped entry (`/usr/share/wayland-sessions/hyprland-uwsm.desktop`,
  shipped by the `hyprland` COPR package itself) — the latter has to be
  masked too because it launches uwsm by referencing the `hyprland.desktop`
  ID, and `Hidden=true` makes that ID vanish for *every* consumer, including
  uwsm's own lookup, not just GDM's session picker; masking it any other way
  would leave a second, broken-if-selected entry in the list. All masking is
  same-filename/higher-priority-XDG-dir/`Hidden=true` per the Desktop Entry
  Spec — none of the original package files are touched or deleted, so a
  package update can't disturb this, and any of it reverts instantly by
  deleting the corresponding mask file.
  uwsm is required for this. It comes from the `hermitfeather/hyprland`
  COPR, restricted to `includepkgs=uwsm` so it can never touch the Hyprland
  package itself (that comes from the `ashbuk/Hyprland-Fedora` COPR). It was
  originally from `solopasha/hyprland`, but that owner stopped Hyprland
  packaging in 2025-10 and dropped the Fedora 44 chroot in 2026-09, so that
  repo is disabled. hermitfeather was chosen in 2026-09 because it builds
  from a public git repo, covers Fedora 43-45 and rawhide, and maintains
  the whole Hyprland stack. Fedora's own package review for uwsm is
  https://bugzilla.redhat.com/2426865 -- swap to it if it ever lands.
  **If login ever fails after this change:** switch to a TTY (Ctrl+Alt+F3),
  log in there, and either `sudo rm /usr/local/share/wayland-sessions/hyprland.desktop`
  to instantly bring back the plain entry, or run `Hyprland` directly from
  the TTY for a bare session.

## Notes

- Don't mention Claude Code in commit messages
- Services (redis, mysql) can be started with `docker compose up -d` if needed
