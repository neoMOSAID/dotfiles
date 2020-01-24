#!/bin/bash
is_running=$( pgrep -fc  "$(realpath "$0" )" )
if (( $is_running >= 2 )) && [[ -n "$BLOCK_BUTTON" ]] ; then
    >&2 echo ${0##*/} is running $is_running proccess
    exit 1
fi
size=35
msgId="991041"
myPath="${HOME}/OneDrive/OneDrive/linux"
pplayScript="${HOME}/.i3/pplay/play.sh"
pid="$(  "$pplayScript" pid )"
mp1=' mpc --host=127.0.0.1 --port=6601 '
mp2=' mpc --host=127.0.0.1 --port=6602 '
if [[ -f /tmp/mpd_mode ]]
    then mp="$mp2"
    else mp="$mp1"
fi

function mpv_str(){
    str1="$(  "$pplayScript" index )/"
    str1+="$(  "$pplayScript" N )"
    str1+=" $(  "$pplayScript" time )/"
    str1+="$(  "$pplayScript" totaltime )"
    if (( $( $pplayScript m ) == 9 ))
        then str2="##############"
        else str2="$( "$pplayScript" title )"
    fi
    if (( ${#str2} > $size )) ; then
        ll=${#str2}		    #length of str
        zz=$((ll-size))		#excess
        str2=${str2::(-zz)}
    fi
    if [[ "$1" == "mode1" ]]
        then echo "$str1"
        else echo "$str2"
    fi
}

function mpd_str(){
    str="$( $mp status|awk '
        BEGIN{s=""}
        NR==1{s=$0}
        NR==2{s= substr($2, 2, length($2)) " " $3 "|" s}
        END{print s}
    ' )"
    str1=${str%%|*}
    str2=${str##*|}
    if (( ${#str2} > $size )) ; then
        ll=${#str2}		    #length of str
        zz=$((ll-size))		#excess
        str2=${str2::(-zz)}
    fi
    if [[ "$1" == "mode1" ]]
        then echo "$str1"
        else echo "$str2"
    fi
}

function mode1_mpv_cmd(){
    case $1 in
        1)
            WorkSpaceName=$(i3-msg -t get_workspaces | jq -c '.[] |select(.focused)|.name' )
            i3-msg "workspace $WorkSpaceName;  exec --no-startup-id  rofi -show combi " \
                >/dev/null
            ;;
        3)
            WorkSpaceName=$(i3-msg -t get_workspaces | jq -c '.[] |select(.focused)|.name' )
            i3-msg "workspace $WorkSpaceName;  exec --no-startup-id  lxterminal " \
                >/dev/null
            ;;
        4)  ${myPath}/scripts0/media-controls.sh v  >/dev/null ;;
        5)  ${myPath}/scripts0/media-controls.sh vv >/dev/null ;;
    esac
}

function mode2_mpv_cmd(){
    case $1 in
        1)
            WorkSpaceName=$(i3-msg -t get_workspaces | jq -c '.[] |select(.focused)|.name' )
            cmd="lxterminal -e $pplayScript list "
            i3-msg "workspace $WorkSpaceName;  exec --no-startup-id $cmd " \
                >/dev/null
            ;;
        3)  ${myPath}/scripts0/media-controls.sh pp >/dev/null ;;
        4)  ${myPath}/scripts0/media-controls.sh p  >/dev/null ;;
        5)  ${myPath}/scripts0/media-controls.sh n >/dev/null ;;
    esac
}

function mode1_mpd_cmd(){
    case $1 in
        1)
            WorkSpaceName=$(i3-msg -t get_workspaces | jq -c '.[] |select(.focused)|.name' )
            i3-msg "workspace $WorkSpaceName;  exec --no-startup-id  rofi -show combi " \
                >/dev/null
            ;;
        3)
            WorkSpaceName=$(i3-msg -t get_workspaces | jq -c '.[] |select(.focused)|.name' )
            i3-msg "workspace $WorkSpaceName;  exec --no-startup-id  lxterminal " \
                >/dev/null
            ;;
        5) msg=$( $mp volume -2|awk 'NR==3{print $2}' )
            dunstify  -r "$msgId" "music player daemon: $msg"
            ;;
        4) msg=$( $mp volume +2|awk 'NR==3{print $2}' )
            dunstify  -r "$msgId" "music player daemon: $msg"
            ;;
    esac

}

function mode2_mpd_cmd(){
    case $1 in
        1)
            WorkSpaceName=$(i3-msg -t get_workspaces | jq -c '.[] |select(.focused)|.name' )
            cmd="lxterminal -e bash "
            cmd+="${HOME}/OneDrive/OneDrive/linux/scripts2/myBash_functions.sh mm"
            i3-msg "workspace $WorkSpaceName;  exec --no-startup-id $cmd"
            ;;
        3) $mp toggle  >/dev/null ;;
        5) msg=$( $mp next |head -1 )
            dunstify  -r "$msgId" "music player daemon:" "$msg"
            ;;
        4) msg=$( $mp prev|head -1 )
            dunstify  -r "$msgId" "music player daemon:" "$msg"
            ;;
    esac

}

if [[ -n "$pid" ]]  # mpv is playing
    then
        echo "$(mpv_str "$1" )"
        [[ -z "$BLOCK_BUTTON" ]] && exit
        if [[ $1 == "mode1" ]] ;
            then mode1_mpv_cmd "$BLOCK_BUTTON"
            else mode2_mpv_cmd "$BLOCK_BUTTON"
                 [[ -n "$BLOCK_BUTTON" ]] && sleep 2
        fi
    else
        echo "$(mpd_str "$1" )"
        [[ -z "$BLOCK_BUTTON" ]] && exit
        if [[ $1 == "mode1" ]] ;
            then mode1_mpd_cmd "$BLOCK_BUTTON"
            else mode2_mpd_cmd "$BLOCK_BUTTON"
                [[ -n "$BLOCK_BUTTON" ]] && sleep 2
        fi

fi


#str=$(wmctrl -l |grep youtube |head -1| awk '{ for(i=4;i<NF-1;i++)printf("%s ",$i)}')
#if ! [ -z "$str" ] ; then
#	if (( ${#str} > $size )) ; then  str=${str:(-size)} ; fi
#	echo "$str"
#	exit
#fi
#echo "${str}"|sed 's/,request_id:0//'

#if (( ${#str2} > $size )) ; then
#    tmp1=${str%%|*}		#first part of str (before # )
#    ll=${#str}		    #length of str
#    zz=$((ll-size))		#excess
#    tmp2=${str#*|}		#second part of str (after # )
#    yy=${#tmp2}		    #length of second part
#    yyy=$((yy-zz))
#    tmp2=${tmp2::yyy}
#    #tmp2=${tmp2:(-yyy)}
#    str2="${tmp1}|${tmp2}"
#fi

