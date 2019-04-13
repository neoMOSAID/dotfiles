#!/bin/bash
scriptname=$( basename "$0" )
is_running=$( pgrep -cf "$scriptname" )
if (( $is_running > 1 )) ; then
  >&2 echo $scriptname is running.
  exit 0
fi

wallhavenPhp="${HOME}/gDrive/gDrive/linux/scripts2/getWallpHaven/db.php"

function getws () {
    lastWS=$(cat ~/.i3/.ws )
    currWS=$(i3-msg -t get_workspaces \
                        | jq -c '.[] |select(.focused)|.num' )
    if (( $lastWS != $currWS )) ; then
        echo "$currWS" >| ~/.i3/.ws
        php -f "$wallhavenPhp" f=wh_set "expired" "0"
        return "$currWS"
    fi
    return 0  #same ws
}

ii=0
while true ; do
    getws
    index=$?
    if (( $currWS == 8 && $ii >= 7 )) \
       || (( $currWS == 10 && $ii >= 7 )) \
       || (( $index != 0 )) \
       || (( $ii > 30 )) ; then
        bash ${HOME}/.i3/wchanger.sh >/dev/null
        ii=0
    fi
    ii=$((ii+1))
    sleep 1
done

