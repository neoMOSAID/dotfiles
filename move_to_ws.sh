#!/bin/bash
ws=$(
    zenity --entry --text="workspace:" --title="Move window"
)

number='^[0-9]+$'
if ! [[ "$ws" =~ $number ]] || (( $ws == 0 ))
    then exit
fi

if (( $ws <= 13 )) ; then
    wsn=$(~/.i3/workspaces.sh "$ws" )
    ws=$wsn
fi

if [[ "$1" == "move" ]]
    then
        i3-msg "move container to workspace $ws"
    else
        i3-msg "workspace $ws"
fi

