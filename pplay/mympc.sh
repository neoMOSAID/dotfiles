#!/bin/bash
function printhelp () {
  printf '\033[1;33m  %-15s\t\033[1;37m%s\n' "$1" "$2"
}
mympc="mpc --host=127.0.0.1 --port=6601 "
case "$1" in
	"" )  $mympc -q  next  ;;
	"c")  ;;
	"s") if [ -z "$2" ]
		then $mympc -q  stop
	        else
		     ii=0
		     for i do
			if (($ii!=0)) ; then query+="$i|" ; fi
			ii=$((ii+1))
		     done
		     query=${query::-1}
		     "$0" ll |grep --color=always -i -E "$query"| sort -n | uniq
	     fi
             exit ;;
       "pp"|"m") if ! `$mympc |grep -F "playing">/dev/null`
		then $mympc -q play
		else $mympc -q pause
	     fi
	;;
	"p") $mympc -q  prev ;;
	"n") $mympc -q  next ;;
	"v") $mympc   volume +2|awk 'NR==3{print $2}' ;;
  "vv") $mympc   volume -2|awk 'NR==3{print $2}' ;;
	"h"|"H"|"help")
    printf "\t \033[1;32m my script to control mpd \033[1m\n"
		printhelp  "h,H,help" "print this help"
		printhelp  "c" "currently playing song"
		printhelp  "" "play next"
		printhelp  "pp,m" "play/pause"
		printhelp  "p" "previous"
		printhelp  "n" "next"
		printhelp  "v" "volume +2"
		printhelp  "vv" "volume -2"
		printhelp  "s" "stop"
		printhelp  "s   [pattern]" "search index of song(s) with pattern(s)"
		printhelp  "[number]" "play nth song"
		printhelp  "a   [patterns]" "add songs with patter(n) to current playlist"
		printhelp  "ll" "print current playlists"
        printhelp  "d" "remove current song from playlist"
		printhelp  "ss  [patterns]" "print result of search pattern(s)"
		printhelp  "sl  [patterns]" "play songs with pattern(s)"
		printhelp  "ssl [patterns]" "print then play songs with pattern(s)"
		printhelp  "save [name]" "save current playlist"
		printhelp  "l   [playlist]" "load playlist"
		printhelp  "*" "other commands accepted by mpc"
	exit
	;;
        "a") $mympc search any "$2" | $mympc add  ;;
       "ll") index=$($mympc status -f "%position%" |head -1)
	     $mympc playlist|awk '{$0=substr($0,0,60) ; print $0 }'\
	       |nl| less +"$index"
	exit
	;;
       "sl"|"ss"|"ssl")
	     ii=0
	     ss=$( $mympc search  any "")
	     ss+="\n"
	     for i do
		if (($ii!=0)) ; then
		ss+=$( $mympc search  any "$i")
		ss+="\n"
		query+="$i|"
		fi
		ii=$((ii+1))
	     done
	     query=${query::-1}
	     if [[ "$1" == "ss" || "$1" == "ssl" ]] ; then
		     printf "$ss" |grep --color=always -i -E "$query"| sort -n | uniq
	     fi
	     if [[ "$1" == "sl" || "$1" == "ssl" ]] ; then
		     printf "$ss" |grep -i -E "$query" | sort -n | uniq >| "$HOME/.mpd/playlist/tmp.m3u"
	     	     "$0" l tmp|grep -v ^loading
	             rm "$HOME/.mpd/playlist/tmp.m3u"
	     fi
	exit
	;;
	"save") $mympc rm "$2" 2>/dev/null; $mympc save "$2" ;;
	"l") $mympc -q clear
	     $mympc -q load $2
	     $mympc -q play ;;
    "d")
        index=$($mympc status -f "%position%" |head -1)
        CURRENT="$( $mympc -f "%file%" playlist | sha512sum )"
        while read -r line
        do
            i="$( $mympc -f "%file%" playlist $line | sha512sum )"
            if [ "$i" = "$CURRENT" ]; then
                break
            fi
        done <<< "$( $mympc lsplaylist )"
        $mympc del 0
        $mympc rm "$line"
        $mympc save "$line"
        $mympc -q clear
        echo "removed from $line"
        $mympc -q load "$line"
        $mympc -q play $index
        exit
        ;;
	  *)
		number='^[0-9]+$'
		if [[ $1 =~ $number ]]
			then $mympc -q play "$1"
			else $mympc  "$@"
		fi
		exit
	;;
esac
title=$($mympc status -f "%title%" |head -1)
artist=$($mympc status -f "%artist%" |head -1)
file=$($mympc status -f "%file%" |head -1)
index=$($mympc status -f "%position%" |head -1)
size=$($mympc status |awk 'NR==2{print $2}'|cut -d'/' -f2)
stats=$( $mympc status |awk 'NR==2{printf("%s - %s",$2,$3) }' )
stats=${stats:1}
if ! [[ -z "$artist" && -z "$title" ]]
	then str="$artist - ${title##*/}"
	else str="${file##*/}"
fi
echo "$stats # $str"

