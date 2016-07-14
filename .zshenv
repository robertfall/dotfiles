export LC_ALL=en_ZA.UTF-8
export LANG=en_ZA.UTF-8
export PATH=./node_modules/.bin:$PATH

[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx
