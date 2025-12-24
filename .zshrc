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
#bindkey '^j' jq-complete
antigen apply

autoload edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats '(%b%u%c)'

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

set -o emacs

#alias op="op.exe"
eval "$(op completion zsh)"; compdef _op op.exe

alias cursor="/mnt/c/Users/Robert\ Herbst/AppData/Local/Programs/cursor/resources/app/bin/cursor"

alias inject_secrets=". ~/.secrets"
 
# Set up the prompt (with git branch name)
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{green}${vcs_info_msg_0_}%f %F{red}$%f '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -U +X bashcompinit && bashcompinit
<<<<<<< HEAD
complete -o nospace -C /opt/homebrew/bin/terraform terraform

complete -o nospace -C /opt/homebrew/Cellar/tfenv/3.0.0/versions/1.2.6/terraform terraform
=======
>>>>>>> ec16113 (Split .zshrc into OS specific files)

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
#compdef gt
###-begin-gt-completions-###
#
# yargs command completion script
#
# Installation: /opt/homebrew/bin/gt completion >> ~/.zshrc
#    or /opt/homebrew/bin/gt completion >> ~/.zprofile on OSX.
#
_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" /opt/homebrew/bin/gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt
###-end-gt-completions-###

<<<<<<< HEAD

eval "$(atuin init zsh)"

# pnpm
export PNPM_HOME="/home/rob/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

. "$HOME/.atuin/bin/env"
. "$HOME/.config/wezterm/shell-integration.sh"

ulimit -S -n 65536

# Open new tabs in same directory
keep_current_path() {
  printf "\e]9;9;%s\e\\" "$(wslpath -w "$PWD")"
}
precmd_functions+=(keep_current_path)

# added by Snowflake SnowSQL installer
export PATH=/home/rob/bin:$PATH

# DuckDB 
export PATH='/home/rob/.duckdb/cli/latest':$PATH
=======
eval "$(atuin init zsh)"

# MacOS Only
[[ "$OSTYPE" == darwin* ]] && . ~/.zshrc.macos
>>>>>>> ec16113 (Split .zshrc into OS specific files)
