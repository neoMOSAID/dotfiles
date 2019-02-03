#!/bin/bash
script="/home/mosaid/gDrive/gDrive/www/phpTests/Lyrics2/populate.sh"
play="/home/mosaid/gDrive/gDrive/linux/scripts0/play.sh" 
mpcplay="/home/mosaid/gDrive/gDrive/linux/scripts2/mympc.sh"

scriptname=$( basename "$0" )
is_running=$( pgrep -c "$scriptname" )
if (( $is_running > 1 )) && [ -z "$1" ] ; then
	>&2 echo $scriptname is running.
	exit 0
fi

while true ; do
	#killengine=$(cat /home/mosaid/.i3/.killengine)	
	#if (( $killengine == 1 )) ; then
	#	echo "0" >| /home/mosaid/.i3/.killengine
	#	exit
	#fi
	sleep 5

	n=$( bash "$play" o 2>/dev/null|awk -F/ '{print $1}' )
	d=$( cat /home/mosaid/.pplaymode )
	if ! [[ -z "$n" ]] && (( "$d" != 5 )) ; then
		n=$((n+1))
		lastPlayed=$(cat /home/mosaid/.pplayLastPlayed )
		nowPlaying=$( bash "$play" l |sed -n "$n,$"p |head -1)
		if [[ "$nowPlaying" != "$lastPlayed" ]] ; then
			echo "$nowPlaying" >| /home/mosaid/.pplayLastPlayed
			bash "$script"  
		fi
		continue
	fi
	if ! mpc --host=127.0.0.1 --port=6601 |grep -F "[paused]" >/dev/null ; then 
		lastPlayed=$(cat /home/mosaid/.pplayLastPlayed )
		nowPlaying=$( bash "$mpcplay" c |cut -d# -f2 )
		if [[ "$nowPlaying" != "$lastPlayed" ]] ; then
			echo "$nowPlaying" >| /home/mosaid/.pplayLastPlayed
			bash "$script"  
		fi
		continue
	fi
done

