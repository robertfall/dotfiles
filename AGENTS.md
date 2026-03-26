# Dotfiles Repo Notes for Agents

## Scope
- This repo is a personal, multi-OS-aware dotfiles/config repo.
- The setup is designed around a shared base plus platform overlays, primarily macOS (`.zshrc.macos`) and Linux/WSL (`.zshrc.wsl`, WezTerm WSL domain behavior).
- Main managed areas: shell (`.zshrc*`), tmux (`.tmux.conf`), Neovim (`nvim/**`), WezTerm (`wezterm/wezterm.lua`), and local `opencode` config (`opencode/**`).

## Repo Layout
- `.zshrc`, `.zshrc.wsl`, `.zshrc.macos`: base shell config plus OS-specific overlays.
- `.tmux.conf`: tmux defaults, clipboard passthrough, pane/window behavior.
- `nvim/init.lua` + `nvim/lua/nvimconfig/**`: Neovim config and plugin specs.
- `nvim/lazy-lock.json`: pinned Neovim plugin commits.
- `wezterm/wezterm.lua`: WezTerm terminal config.
- `opencode/opencode.json`: opencode permission policy.

## High-Signal Behavior

### Shell (`.zshrc`)
- Uses `mise` (`eval "$(~/.local/bin/mise activate zsh)"`).
- Uses `antigen` with `agkozak/zsh-z` and `reegnz/jq-zsh-plugin`.
- Uses `atuin` history (`eval "$(atuin init zsh)"`).
- Prompt includes `vcs_info` branch state and prints command timing in `precmd`.
- Defines `gch()` helper to fuzzy-select and checkout branches via `fzf`.
- Loads OS-specific config:
  - macOS: `.zshrc.macos`
  - Linux/WSL: `.zshrc.wsl`

### WSL-Specific Shell (`.zshrc.wsl`)
- Adds Neovim and `opencode` binaries to `PATH`.
- Sets `GIT_SSH_COMMAND=ssh.exe`.
- Runs WezTerm shell integration script.
- Sends OSC `9;9` in `precmd` so new WezTerm tabs start in current directory.

### tmux (`.tmux.conf`)
- Uses `tmux-256color`, truecolor override, `vi` mode keys.
- Enables clipboard passthrough (`set-clipboard on`, `allow-passthrough on`).
- Status bar is top-aligned.
- Splits/new windows start in current pane directory.

### Neovim
- Leader is comma: `vim.g.mapleader = ","`.
- Plugin manager: `lazy.nvim` bootstrap in `nvim/lua/nvimconfig/lazy_init.lua`.
- LSP uses Neovim 0.11 native APIs (`vim.lsp.config` / `vim.lsp.enable`).
- Expected language servers on PATH: `ruby-lsp`, `rust-analyzer`, `vtsls`.
- Formatting via `conform.nvim` is manual (`<leader>f`), not format-on-save.
- Tree-sitter installed for JS/TS/TSX/Ruby/Rust/Markdown/Diff/Lua/Vim/C/Query.
- WSL clipboard integration is explicitly configured in `set.lua`.

### WezTerm (`wezterm/wezterm.lua`)
- Defaults to domain `WSL:Ticketsolve`.
- Theme/font: `nord` + `Fira Code` at `12`.
- Leader key: `CTRL+l`.
- Custom `CTRL+c`: copies selection if present, otherwise sends interrupt.
- Split bindings:
  - `LEADER|CTRL+s`: vertical split
  - `LEADER|CTRL+d`: horizontal split

### opencode
- `opencode/opencode.json` allows many common commands by pattern, defaults others to ask.
- Read policy denies `.env`/`.env.*` except `*.env.example`.
- `opencode/package.json` depends on `@opencode-ai/plugin@1.1.34`.
- `opencode/bun.lock` pins `@opencode-ai/plugin`, `@opencode-ai/sdk`, and `zod`.

## Important Gotchas
- `nvim/undodir` is ignored by `.gitignore`, but undo files are already tracked in git history.
- Files in `nvim/undodir/**` are Vim undo binary artifacts (not normal source files).
- Do not treat tracked `nvim/undodir/**` files as project logic; they are editor state.
- `opencode/.gitignore` ignores local opencode dependency files (`node_modules`, `package.json`, `bun.lock`, `.gitignore`) inside that subdir, so `opencode/**` may be intentionally local-only state.

## Working Conventions
- Prefer minimal, targeted edits in the relevant config file.
- If changing Neovim plugins, update plugin spec files under `nvim/lua/nvimconfig/lazy/` and keep `nvim/lazy-lock.json` consistent.
- Keep shell changes OS-aware by placing platform-specific logic in `.zshrc.macos` or `.zshrc.wsl` when appropriate.
- Preserve CRLF in `wezterm/wezterm.lua` unless intentionally normalizing line endings.
