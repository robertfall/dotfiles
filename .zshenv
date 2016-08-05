export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
