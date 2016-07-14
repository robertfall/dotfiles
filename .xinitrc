#!/bin/sh

xrdb -merge $HOME/.Xdefaults

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

feh --bg-scale /home/roberthe/images/dawn.jpg
eval $(ssh-agent)
#compton &
powerline-daemon
exec herbstluftwm
