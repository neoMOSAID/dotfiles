#!/bin/bash
size=60
myPath="${HOME}/OneDrive/OneDrive/linux"
pplayScript="${myPath}/scripts0/pplay/newplay.sh"
pid="$( bash "$pplayScript" pid )"
mp=' mpc --host=127.0.0.1 --port=6601 '
if ps -p "$( bash "$pplayScript" pid )" > /dev/null
    then
            str="$( bash "$pplayScript" index )|"
            str+="$( bash "$pplayScript" title )"
            case $BLOCK_BUTTON in
                1)  ${myPath}/scripts0/media-controls.sh pp ;;
                3)  ${myPath}/scripts0/media-controls.sh n ;;
                4)  ${myPath}/scripts0/media-controls.sh v ;;
                5)  ${myPath}/scripts0/media-controls.sh vv ;;
            esac
            if (( ${#str} > $size )) ; then
                ll=${#str}		    #length of str
                zz=$((ll-size))		#excess
                str=${str::(-zz)}
            fi
    else
            str=$( ${myPath}/scripts2/mympc.sh c|sed 's/ - / | /')
            case $BLOCK_BUTTON in
                1) echo "$str"
                    WorkSpaceName=$(i3-msg -t get_workspaces | jq -c '.[] |select(.focused)|.name' )
                    i3-msg "workspace $WorkSpaceName;  exec --no-startup-id lxterminal -e bicon.bin ncmpcpp "
                    ;;
                3) $mp toggle  >/dev/null ;;
                4) $mp prev    >/dev/null ;;
                5) $mp next    >/dev/null ;;
            esac
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
fi


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





