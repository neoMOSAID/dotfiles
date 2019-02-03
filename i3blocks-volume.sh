#!/bin/bash

DEFAULT=$(pactl info | awk '/Default Sink/{print $3}')
INDEX=$(pactl list sinks short | awk "/$DEFAULT/"'{print $1}')

# Get Volume
VOLUME=$(pactl list sinks | grep "Sink #$INDEX\|^[[:space:]]Volume:" \
  | grep -A 1 "Sink #$INDEX" | grep "^[[:space:]]Volume" \
  | awk '{print $5}' )
VOLUME1=$(echo $VOLUME|head -1)

# Get Mute Status
MUTE=$(pactl list sinks | grep "Sink #$INDEX\|Mute" | grep -A 1 "Sink #$INDEX" | grep Mute | awk '/Mute/{print $2}')

ICON=
COLOR="#FFFFFF"

if [[ $MUTE == "yes" ]] ; then
  ICON=
  COLOR="#FF0000"
fi

echo "$ICON$VOLUME1"
echo
echo $COLOR

if [ -z "$BLOCK_BUTTON" ] ; then
    BLOCK_BUTTON=0
fi
case "$BLOCK_BUTTON" in
    1)  #left click
          if [ $MUTE == "yes" ]
              then pactl set-sink-mute $INDEX 0
              else pactl set-sink-mute $INDEX 1
          fi
          pkill -RTMIN+9 i3blocks ;;
    3)  #right click
        pavucontrol ;;
    4)  #WHEEL UP
        pactl set-sink-volume $INDEX +5%
        pkill -RTMIN+9 i3blocks ;;

    5)  #WHEEL DOWN
        pactl set-sink-volume $INDEX -5%
        pkill -RTMIN+9 i3blocks ;;

esac

