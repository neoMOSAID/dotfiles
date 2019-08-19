#!/bin/bash

scriptname=$( basename "$0" )
is_running=$( pgrep -c "$scriptname" )
if (( $is_running > 1 )) && [ -z "$1" ] ; then
    >&2 echo $scriptname is running.
    exit 0
fi

shut="${HOME}/OneDrive/OneDrive/linux/scripts2/myBash_functions.sh shut "
m1="/home/mosaid/.i3/pplay/mpvp.sh"
pplayScript="/home/mosaid/.i3/pplay/play.sh"

function ws_f(){
    if (( $1>0 && $1 <= 13 ))
        then
            wsn=$( bash /home/mosaid/.i3/workspaces.sh $1 )
        else
            wsn=$1
    fi
    i3-msg "workspace $wsn"
}

while true ; do
    sleep 5
    if ! [[ -f /tmp/cmd_trigger_tr ]]
        then continue
    fi
    cmd="$(cat /tmp/cmd_trigger_cmd )"
    arg="$(cat /tmp/cmd_trigger_arg )"
    >&2 echo "trigger: $cmd ~ $arg"
    rm /tmp/cmd_trigger_tr
    case "$cmd" in
        pplay ) "$pplayScript" "$arg" ;;
        m1 )    "$m1" "$arg" ;;
        shut )  lxterminal -e "$shut $arg" ;;
        ws)     ws_f "$arg" ;;
    esac
done
