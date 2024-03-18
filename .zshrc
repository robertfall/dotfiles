# Basic
autoload -U compinit && compinit
autoload -Uz vcs_info
precmd() { vcs_info }

# ASDF
. /opt/homebrew/opt/asdf/libexec/asdf.sh 

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
 
# Set up the prompt (with git branch name)
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{green}${vcs_info_msg_0_}%f %F{red}$%f '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

complete -o nospace -C /opt/homebrew/Cellar/tfenv/3.0.0/versions/1.2.6/terraform terraform

export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

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

export PERCY_TOKEN=web_ac74fd2c62f4848bd4c47ec7eee30a088c7b78f9f3c379996d2b603e50795c68

eval "$(atuin init zsh)"
