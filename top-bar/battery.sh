#!/bin/bash

msgId="991051"

function light_f(){
    [[ "$1" == "+" ]] && light -A 2
    [[ "$1" == "-" ]] && light -U 2
    LIGHT=$(light)
    dunstify  -r "$msgId" "LIGHT : $LIGHT"
}

function redshift_if(){
    if pgrep redshift >/dev/null
    then
        dunstify  -r "$msgId" "redshift is running"
    else
        dunstify  -r "$msgId" "redshift is not running"
    fi
}

function redshift_f(){
    if pgrep redshift >/dev/null
        then
            dunstify  -r "$msgId" "stopping redshift..."
            killall redshift
        else
            dunstify  -r "$msgId" "starting redshift..."
            redshift >/dev/null & disown
    fi
    #pkill -RTMIN+10 i3blocks
}

case $BLOCK_BUTTON in
    1) redshift_f    ;;
    3) redshift_if    ;;
    4) light_f +     ;;
    5) light_f -     ;;
esac

function alarm() {
  ( speaker-test -t sine -f 1000 )&
  pid=$!
  \sleep 0.${1}s
  \kill -9 $pid
}

function timeConvert(){
    local t=$1
    local k=1
    if [[ ${t:(-1)} == h ]] ; then k=3600 ; fi
    if [[ ${t:(-1)} == m ]] ; then k=60   ; fi
    t=${t/[hms]/}
    t=$( bc -l <<< "$t * $k " )
    t=${t%.*}
    h=$( date -u -d @${t} +"%H" )
    m=$( date -u -d @${t} +"%M" )
    [[ $h == '00' ]] || H=$(($h+0))h
    [[ $m == '00' ]] || M=$(($m+0))m
    echo "${H}${M}"
}

data=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0)

state=$(echo "$data"|grep state|awk -F: '{print $2}')
state=${state//[[:blank:]]/}

percentage=$(echo "$data"|grep percentage|awk -F: '{print $2}')
percentage=${percentage//[[:blank:]]/}
percentage=${percentage::-1}

timetoFull=$(echo "$data"|grep 'time to full'|awk -F: '{$1="";print $0}')
timetoFull=${timetoFull//[[:blank:]]/}
timetoFull=${timetoFull/minutes/m}
timetoFull=${timetoFull/hours/h}


timetoEmpty=$(echo "$data"|grep 'time to empty'|awk -F: '{$1="";print $0}')
timetoEmpty=${timetoEmpty//[[:blank:]]/}
timetoEmpty=${timetoEmpty/minutes/m}
timetoEmpty=${timetoEmpty/hours/h}


case "$percentage" in
           [1-9]|1[0-9])   COLOR="#FF0000"
                           ICON=
                           if [[ "$state" == "discharging" ]] ; then
                               alarm 300 >/dev/null
                               ddd=0
                           fi ;;
                 2[0-9])   COLOR="#fb7603"
                           ICON=
                           ;;
             [3-4][0-9])   COLOR="#fea204"
                           ICON=
                           ;;
      [5-6][0-9]|7[0-5])   COLOR="#bada55"
                           ICON=
                           ;;
      7[6-9]|[8-9][0-9])   COLOR="#00FF00"
                           ICON=
                           ;;
                    100)   COLOR="#00FF00"
                           ICON=
                           ;;
esac

if [[ "$state" == "charging" ]] ; then
    ch="+$( timeConvert $timetoFull )"
fi

if [[ "$state" == "discharging" ]] ; then
    ch="-$( timeConvert $timetoEmpty )"
fi

if pgrep redshift >/dev/null
    then r=""
    else r=""
fi
l=$(light|sed 's/\.[0-9]*//')

echo "$ICON$percentage|$l$r $ch"
echo
echo "$COLOR"



