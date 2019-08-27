#!/bin/bash
date '+%a %d %h %Y %H:%M'

msgId=11111
wsi=$(cat /tmp/my_i3_ws)
wsn=$( bash /home/mosaid/.i3/workspaces.sh $wsi )
case "$BLOCK_BUTTON" in
    1)  n=$(echo $((`date '+%d'`))|wc -c )
        msg="$(cal -m)"
        msg+="Upcoming Prayer"
        msg+="$(cat /tmp/nextPrayerTime | sed 's/ Upcoming Prayer //' )"
        dunstify -u normal -r "$msgId"  "$msg" ;;
    3) i3-msg "workspace $wsn;  exec  --no-startup-id lxterminal -e bicon.bin ranger " ;;
    4) wsi=$((wsi-1))
       (( $wsi < 1 )) && wsi=12
       wsn=$( bash /home/mosaid/.i3/workspaces.sh $wsi )
       i3-msg "workspace $wsn" ;;
    5) wsi=$((wsi+1))
        (( $wsi > 12 )) && wsi=1
       wsn=$( bash /home/mosaid/.i3/workspaces.sh $wsi )
       i3-msg "workspace $wsn" ;;
esac


