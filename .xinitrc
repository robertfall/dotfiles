#!/bin/sh

VBoxClient --display
VBoxClient --clipboard

xrdb -merge $HOME/.Xdefaults

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

feh --bg-scale /home/roberthe/images/background.png
eval $(ssh-agent)
powerline-daemon
exec herbstluftwm
