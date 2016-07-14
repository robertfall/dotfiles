# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

setopt appendhistory autocd extendedglob nomatch notify
unsetopt beep
bindkey -v
bindkey '^R' history-incremental-search-backward

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/roberthe/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

alias ls='ls --color=auto'
alias hc='herbstclient'
alias pdf='hc spawn apvlv'
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Docker
alias dc='docker-compose'
alias up='docker-compose up'
alias drun='docker-compose run'
alias d='docker'
alias dstop='docker stop'
alias dstop-all='docker stop `docker ps -q`'
alias docker-kill='docker rm -f `docker ps -qa`'
alias docker-destroy='docker rmi -f `docker images -q`'


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

. /usr/lib/python3.5/site-packages/powerline/bindings/zsh/powerline.zsh
. /usr/lib/z.sh
