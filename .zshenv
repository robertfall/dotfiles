export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export DOCKER_USER_ID=$(id -u)
export DOCKER_USER_NAME=$(id -un)
export RUST_SRC_PATH="$HOME/.multirust/toolchains/beta-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src"

[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
source /usr/share/chruby/chruby.sh

export PATH="$HOME/.cargo/bin:$PATH"
