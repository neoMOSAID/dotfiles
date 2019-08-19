#!/bin/bash
getLyrics="/home/mosaid/OneDrive/OneDrive/www/phpTests/Lyrics2/populate.sh"
getLocalLyrics="/home/mosaid/OneDrive/OneDrive/linux/scripts0/lyrics.sh"
pplayScript="${HOME}/.i3/pplay/play.sh"
mpcplay="${HOME}/.i3/pplay/mympc.sh"

scriptname=$( basename "$0" )
is_running=$( pgrep -c "$scriptname" )
if (( $is_running > 1 )) && [ -z "$1" ] ; then
	>&2 echo $scriptname is running.
	exit 0
fi

while true ; do
	sleep 5
    pplay_pid="$( "$pplayScript" pid )"
    if [[ ! -z $pplay_pid ]] ; then
		nowPlaying=$( bash "$pplayScript" title )
        if `echo "$nowPlaying" | grep 'watch?v=' >/dev/null`
            then continue
        fi
        lastPlayed=$( cat /tmp/pplay_engine_last )
		if [[ "$nowPlaying" != "$lastPlayed" ]] ; then
            echo "$nowPlaying" > /tmp/pplay_engine_last
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
		lastPlayed=$(cat /tmp/pplay_mpd_LastPlayed )
		nowPlaying=$( bash "$mpcplay" c |cut -d# -f2 )
		if [[ "$nowPlaying" != "$lastPlayed" ]] ; then
			echo "$nowPlaying" > /tmp/pplay_mpd_LastPlayed
            code=$(ping -c 1 8.8.8.8 2>&1 |grep unreachable >/dev/null; echo $? )
            if (( code == 0 ))
                then bash "$getLocalLyrics" 1
                else bash "$getLyrics"
            fi
		fi
		continue
	fi
done

