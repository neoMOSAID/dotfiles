#!/bin/bash
LC_ALL=ar_MA.utf8 date '+%H:%M ,%A %d %h %Y'

msgId=11111
wsi=$(cat /tmp/my_i3_ws)
wsn=$( bash /home/mosaid/.i3/workspaces.sh $wsi )
case "$BLOCK_BUTTON" in
    1)  n=$(echo $((`date '+%d'`))|wc -c )
        title=$(date '+%H:%M ,%A %d %h %Y')
        msg="$(echo;cal --color=always -m|sed '1d')"
        #msg+="$(echo)"
        #msg+="$(cat /tmp/nextPrayerTime | sed 's/ Upcoming Prayer //' )"
        dunstify -u normal -r "$msgId" "$title" "$msg" ;;
        # -e bicon.bin ranger
    3) i3-msg "workspace $wsn;  exec  --no-startup-id lxterminal" ;;
    4) wsi=$((wsi-1))
       (( $wsi < 1 )) && wsi=12
       wsn=$( bash /home/mosaid/.i3/workspaces.sh $wsi )
       i3-msg "workspace $wsn"
       #dunstify -u normal -r "$msgId"  "workspace $wsn"
       ;;
    5) wsi=$((wsi+1))
        (( $wsi > 12 )) && wsi=1
       wsn=$( bash /home/mosaid/.i3/workspaces.sh $wsi )
       i3-msg "workspace $wsn"
       #dunstify -u normal -r "$msgId"  "workspace $wsn"
       ;;
esac


