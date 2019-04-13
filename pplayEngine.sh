#!/bin/bash
getLyrics="/home/mosaid/gDrive/gDrive/www/phpTests/Lyrics2/populate.sh"
getLocalLyrics="/home/mosaid/gDrive/gDrive/linux/scripts0/lyrics.sh"
pplayScript="/home/mosaid/gDrive/gDrive/linux/scripts0/pplay/newplay.sh"
mpcplay="/home/mosaid/gDrive/gDrive/linux/scripts2/mympc.sh"

scriptname=$( basename "$0" )
is_running=$( pgrep -c "$scriptname" )
if (( $is_running > 1 )) && [ -z "$1" ] ; then
	>&2 echo $scriptname is running.
	exit 0
fi

while true ; do
	sleep 5
    pplay_pid="$(cat "${HOME}/.pplay_pid")"
    if ps -p $pplay_pid > /dev/null ; then
		nowPlaying=$( bash "$pplayScript" title )
        if `echo "$nowPlaying" | grep 'watch?v=' >/dev/null`
            then continue
        fi
        lastPlayed=$( cat "${HOME}/.pplay_engine_last" )
		if [[ "$nowPlaying" != "$lastPlayed" ]] ; then
            echo "$nowPlaying" >| /home/mosaid/.pplay_engine_last
            bash "$pplayScript" saveTitle
            bash "$pplayScript" saveIndex
            code=$(ping -c 1 8.8.8.8 2>&1 |grep unreachable >/dev/null; echo $? )
            if (( code == 0 ))
                then
                    >&2 echo "getting local lyrics"
                    bash "$getLocalLyrics" 1 mpv
                else
                    bash "$getLyrics"
                    >&2 echo "getting remote lyrics"
            fi
		fi
		continue
	fi
	if ! mpc --host=127.0.0.1 --port=6601 |grep -F "[paused]" >/dev/null ; then
		lastPlayed=$(cat /home/mosaid/.pplayLastPlayed )
		nowPlaying=$( bash "$mpcplay" c |cut -d# -f2 )
		if [[ "$nowPlaying" != "$lastPlayed" ]] ; then
			echo "$nowPlaying" >| /home/mosaid/.pplayLastPlayed
			bash "$getLyrics"
            code=$(ping -c 1 8.8.8.8 2>&1 |grep unreachable >/dev/null; echo $? )
            if (( code == 0 ))
                then bash "$getLocalLyrics" 1
                else bash "$getLyrics"
            fi
		fi
		continue
	fi
done

