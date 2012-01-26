#!/bin/bash

new=$1

[[ "$1" = "" ]] && [[ -f /tmp/rotate.norm ]] && new=right

case "$new" in
   left)
      /usr/bin/xsetwacom set stylus Rotate ccw
      /usr/bin/xrandr --orientation left
      /usr/local/bin/synclient Xrandr=2
      rm /tmp/rotate.norm
   ;;
   right)
      /usr/bin/xsetwacom set stylus Rotate cw
      /usr/bin/xrandr --orientation right
      /usr/local/bin/synclient Xrandr=1 RightEdge=650
      rm /tmp/rotate.norm
   ;;
   *)
      /usr/bin/xsetwacom set stylus Rotate none
      /usr/bin/xrandr --orientation normal
      /usr/local/bin/synclient Xrandr=0 RightEdge=830
      touch /tmp/rotate.norm
esac

# /usr/bin/xrandr -s 1152x864
# /usr/bin/xrandr -s 1440x900
