#!/bin/bash
date '+%a %d %h %Y %H:%M'

wsi=$(cat ~/.i3/.ws)
wsn=$( bash /home/mosaid/.i3/workspaces.sh $wsi )
case "$BLOCK_BUTTON" in
    1)  n=$(echo $((`date '+%d'`))|wc -c )
        dunstify "$(cal -m )"   #|sed "s@ $((`date '+%d'`)) @@" )" ;;
        ;;
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


