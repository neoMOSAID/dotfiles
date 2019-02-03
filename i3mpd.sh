#!/bin/bash

mpvPID=$(pgrep mpv)
smplayerPID=$(pgrep smplayer)
size=55
nompc=0
myPath="${HOME}/gDrive/gDrive/linux"

if [[ "$mpvPID" != "" ]] && [[ "$smplayerPID" == "" ]] ; then
	str=$( ${myPath}/scripts0/play.sh oo)
    nompc=1
	if [[ -z "$str" ]] ; then
		str=$(
            wmctrl -l |grep ' - mpv'|head -1|\
            awk '{ for(i=4;i<NF-1;i++)printf("%s ",$i)}'
        )
        nompc=2
	fi
	if (( $BLOCK_BUTTON == 3 || $BLOCK_BUTTON == 1 )) ; then
		#pause mpv
		 ${myPath}/scripts0/media-controls.sh pp
	fi
	case $BLOCK_BUTTON in
		1)  ${myPath}/scripts0/media-controls.sh pp ;;
		3)  ${myPath}/scripts0/media-controls.sh pp ;;
		4)  ${myPath}/scripts0/media-controls.sh v ;;
		5)  ${myPath}/scripts0/media-controls.sh vv ;;
	esac
fi

if [[ -z "$str" ]] ; then
	str=$( ${myPath}/scripts2/mympc.sh c|sed 's/ - / | /')
fi

if (( ${#str} > $size )) ; then
	tmp1=${str%%#*}		#first part of str (before # )
	ll=${#str}		    #length of str
	zz=$((ll-size))		#excess
	tmp2=${str#*#}		#second part of str (after # )
	yy=${#tmp2}		    #length of second part
	yyy=$((yy-zz))
	tmp2=${tmp2::yyy}
	#tmp2=${tmp2:(-yyy)}
	str="${tmp1}#${tmp2}"
fi

mp=' mpc --host=127.0.0.1 --port=6601 '
WorkSpaceName=$(i3-msg -t get_workspaces | jq -c '.[] |select(.focused)|.name' )

case $BLOCK_BUTTON in
	1) echo "$str"
	   i3-msg "workspace $WorkSpaceName;  exec --no-startup-id lxterminal -e bicon.bin ncmpcpp "
	;;
	3) $mp toggle  >/dev/null ;;
	4) $mp prev    >/dev/null ;;
	5) $mp next    >/dev/null ;;
esac

echo "${str}"


#if (($nompc == 1 )) ; then
#    #echo "${#str}"
#    if (( ${#str} > $size ))
#    then
#        ll=$(( ${#str}-$size ))
#        echo "${str::ll}  ${#str}"
#    else
#        echo "${str}  ${#str}"
#    fi
#    exit
#fi

#str=$(wmctrl -l |grep youtube |head -1| awk '{ for(i=4;i<NF-1;i++)printf("%s ",$i)}')
#if ! [ -z "$str" ] ; then
#	if (( ${#str} > $size )) ; then  str=${str:(-size)} ; fi
#	echo "$str"
#	exit
#fi





