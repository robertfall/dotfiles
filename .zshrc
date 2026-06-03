# Basic
autoload -U compinit && compinit
autoload -Uz vcs_info

# Command timing
preexec() {
  cmd_start_time=$SECONDS
}

precmd() {
  vcs_info
  # Show timestamp when command finishes
  if [[ -n $cmd_start_time ]]; then
    local end_time=$SECONDS
    local elapsed=$((end_time - cmd_start_time))
    local timestamp=$(date '+%H:%M:%S')
    echo -e "\033[90m[${timestamp}] (${elapsed}s)\033[0m"
    unset cmd_start_time
  fi
  # OSC 133: mark prompt start so tmux can jump/select between prompts
  # (skip if wezterm shell-integration already emits semantic zones)
  (( ${+functions[__wezterm_semantic_precmd]} )) || print -n '\e]133;A\e\\'
}

# Mise
eval "$(~/.local/bin/mise activate zsh)"

# ZSH plugins via zinit. Self-bootstraps on first run.
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME/.git" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

zinit light agkozak/zsh-z
zinit light reegnz/jq-zsh-plugin

autoload edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats '(%b%u%c)'

set -o emacs

alias inject_secrets=". ~/.secrets"
alias tmux-keep='tmux set destroy-unattached off'

# Set up the prompt (with git branch name)
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{green}${vcs_info_msg_0_}%f %F{red}<\$>%f '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -U +X bashcompinit && bashcompinit

gch() {
 [[ -n "$1" ]] && params+=(--query $1)

 branchname="$(git branch | fzf ${params[@]})"
 return_code="$?"

 if [ "$return_code" -ne 0 ]; then
  return "$return_code"
 fi

 branchname=$(echo $branchname | tr -d '*[:space:]')
 [[ $? -eq 0 ]] && git checkout $branchname
}

[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

ulimit -S -n 65536

# Snowflake SnowSQL
export PATH=$HOME/bin:$PATH

# DuckDB
export PATH="$HOME/.duckdb/cli/latest:$PATH"

# OS-specific config
[[ "$OSTYPE" == darwin* ]] && . ~/.zshrc.macos
if [[ "$OSTYPE" == linux* ]]; then
  . ~/.zshrc.linux
  [[ -n "$WSL_DISTRO_NAME" ]] && . ~/.zshrc.wsl
fi

# Let tmux own mouse-tracking (see .tmux.conf `mouse on`) so wheel scroll
# enters copy mode and `prefix [` keeps working. Otherwise Claude's TUI
# grabs DECSET 1000 and tmux stops seeing mouse events.
export CLAUDE_CODE_DISABLE_MOUSE=1

# Auto-start tmux for interactive shells, but never nest.
# Set NO_TMUX=1 to bypass for a single shell session.
if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -z "$NO_TMUX" ]] && [[ -z "$SSH_CONNECTION" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session \; set-option destroy-unattached on
fi

# Cortex CLI completion (disable via /settings in cortex)
[[ -s ~/.zsh/completions/cortex.zsh ]] && source ~/.zsh/completions/cortex.zsh
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
