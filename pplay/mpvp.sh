#!/bin/bash
mpv_pid="/home/mosaid/.mpv_m1_pid"
if [[ "$1" == k ]] ; then
    pid=$(cat "$mpv_pid" )
    if ! [[ -z "$pid" ]] ; then
        for p in $(echo $pid ) ; do
            kill -9 $p 2>/dev/null
        done
        echo "" >| "$mpv_pid"
    fi
    exit
fi

function f_pid(){
    pid=$(cat "$mpv_pid" )
    if pgrep mpv | grep -w "$pid" >/dev/null
    then echo $pid
    fi
}

case "$1" in
   "") echo "
       1 : mariam
       2 : alanbiaa
       3 : al choarae
       4 : Annour
       5 : Al hajj
       " ;;
    1) file="/home/mosaid/Music/Quran/mariam/mariam.mp3" ;;
    2) file="/home/mosaid/Music/Quran/111/021.mp3" ;;
    3) file="/home/mosaid/Music/Quran/222/1988-1999 - AN-CHOARAE - 227 Ayah.mp3" ;;
    4) file="/home/mosaid/Music/Quran/annour/024 Annour .mp3" ;;
    5) file="/home/mosaid/Music/Quran/111/022.mp3" ;;
    p)
        f_pid
        exit
        ;;
    k)
        kill -9 "$(f_pid)" 2>/dev/null
        exit
esac

#echo "playing : $file"
mpv --force-window=no --really-quiet  --loop "$file" &
pid=$!
echo $pid >> "$mpv_pid"

