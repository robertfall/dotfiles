#!/usr/bin/env bash
#
# Symlink maintenance for these dotfiles.
#
# Re-runnable: links that already point at the repo are left untouched; a
# target that exists as a real file (or a symlink pointing elsewhere) is moved
# aside to <target>.bak-<timestamp> before the correct link is created.
#
# Usage:
#   ./install.sh                         create/refresh core symlinks for this OS
#   ./install.sh --dry-run               show what would happen, change nothing
#   ./install.sh --hyprland              also link Hyprland, Waybar, and Mako
#   ./install.sh --dry-run --hyprland    preview the Hyprland opt-in
#   ./install.sh --help
#
# Written for bash 3.2 (macOS system bash) so it runs unchanged on Linux/WSL.

set -euo pipefail

# Repo root = this script's directory, resolved so CWD doesn't matter.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
INSTALL_HYPRLAND=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --hyprland) INSTALL_HYPRLAND=1 ;;
    --help|-h)
      sed -n '3,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown argument: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

# One timestamp per run, shared by every backup it makes.
TS="$(date +%Y%m%d-%H%M%S)"

n_linked=0 n_ok=0 n_backed=0 n_skipped=0

# run CMD... — execute, or just print it under --dry-run.
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    [dry-run] $*"
  else
    "$@"
  fi
}

# link <repo-relative-source> <absolute-target>
#
# Only the target's *parent* directory is ever created — never the target
# itself. That is what lets us drop a file into a live directory (e.g.
# ~/.config/atuin, which holds atuin's db/key/session) without disturbing it.
link() {
  local src="$DOTFILES/$1" dest="$2" current

  if [ ! -e "$src" ]; then
    printf '  ! %-34s source missing in repo (%s)\n' "$dest" "$1"
    n_skipped=$((n_skipped + 1))
    return
  fi

  run mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      printf '  = %-34s ok\n' "$dest"
      n_ok=$((n_ok + 1))
      return
    fi
    run mv "$dest" "$dest.bak-$TS"
    run ln -s "$src" "$dest"
    printf '  ~ %-34s relinked (was -> %s, backup .bak-%s)\n' "$dest" "$current" "$TS"
    n_backed=$((n_backed + 1))
    return
  fi

  if [ -e "$dest" ]; then
    run mv "$dest" "$dest.bak-$TS"
    run ln -s "$src" "$dest"
    printf '  ~ %-34s backed up + linked (.bak-%s)\n' "$dest" "$TS"
    n_backed=$((n_backed + 1))
    return
  fi

  run ln -s "$src" "$dest"
  printf '  + %-34s linked\n' "$dest"
  n_linked=$((n_linked + 1))
}

is_wsl() {
  [ -n "${WSL_DISTRO_NAME:-}" ] && return 0
  grep -qi microsoft /proc/version 2>/dev/null
}

echo "dotfiles: $DOTFILES"
[ "$DRY_RUN" -eq 1 ] && echo "(dry run — no changes will be made)"
echo

echo "Common:"
link .zshrc            "$HOME/.zshrc"
link .tmux.conf        "$HOME/.tmux.conf"
link .gitconfig        "$HOME/.gitconfig"
link .secrets          "$HOME/.secrets"
link nvim              "$HOME/.config/nvim"
link ghostty           "$HOME/.config/ghostty"
link yazi              "$HOME/.config/yazi"
link atuin/config.toml "$HOME/.config/atuin/config.toml"
link codex/config.toml "$HOME/.codex/config.toml"
link systemd/user/qalc-exchange-rates.service "$HOME/.config/systemd/user/qalc-exchange-rates.service"
link systemd/user/qalc-exchange-rates.timer   "$HOME/.config/systemd/user/qalc-exchange-rates.timer"

case "$OSTYPE" in
  darwin*)
    echo
    echo "macOS:"
    link .zshrc.macos      "$HOME/.zshrc.macos"
    link wezterm/wezterm.lua "$HOME/.wezterm.lua"
    ;;
  linux*)
    echo
    echo "Linux:"
    link .zshrc.linux      "$HOME/.zshrc.linux"
    link wezterm/wezterm.lua "$HOME/.config/wezterm/wezterm.lua"
    if [ "$INSTALL_HYPRLAND" -eq 1 ]; then
      echo
      echo "Hyprland (opted in):"
      link hypr              "$HOME/.config/hypr"
      link waybar            "$HOME/.config/waybar"
      link mako              "$HOME/.config/mako"
      link fuzzel            "$HOME/.config/fuzzel"
      link xdg-desktop-portal/hyprland-portals.conf "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
    fi
    if is_wsl; then
      echo
      echo "WSL:"
      link .zshrc.wsl      "$HOME/.zshrc.wsl"
    fi
    ;;
  *)
    echo
    echo "! Unrecognized OSTYPE='$OSTYPE' — only common links applied." >&2
    ;;
esac

echo
echo "Done: $n_linked linked, $n_backed relinked/backed up, $n_ok already correct, $n_skipped skipped."
