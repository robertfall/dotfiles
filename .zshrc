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
}

# Mise
eval "$(~/.local/bin/mise activate zsh)"

# ZSH Setup
. ~/.zsh/plugins/antigen.zsh
antigen bundle agkozak/zsh-z
antigen bundle reegnz/jq-zsh-plugin
antigen apply

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

# Set up the prompt (with git branch name)
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{green}${vcs_info_msg_0_}%f %F{red}$%f '

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

. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

ulimit -S -n 65536

# Snowflake SnowSQL
export PATH=$HOME/bin:$PATH

# DuckDB
export PATH="$HOME/.duckdb/cli/latest:$PATH"

# OS-specific config
[[ "$OSTYPE" == darwin* ]] && . ~/.zshrc.macos
[[ "$OSTYPE" == linux* ]] && . ~/.zshrc.wsl
