#!/bin/bash

msgId="991148"
scriptname=$( basename "$0" )
is_running=$( pgrep -cf "$scriptname" )
if (( $is_running > 1 )) && [[ -z "$1" ]] ; then
    >&2 echo $scriptname is running.
    exit 0
fi

function CURL (){
    userAgent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:48.0) "
    userAgent+="Gecko/20100101 Firefox/48.0"
    curl -s -A "$userAgent" "$@"
}

CURL 'https://www.islamicfinder.org/' \
|sed -n -e '/Upcoming Prayer/{N;N;N;N;N;N;N;s/<[^>]*>//g;s/\s\s*/ /g;p}' \
>| "/tmp/nextPrayerTime"

if ! [[ -z "$1" ]] ; then exit ; fi

while true ; do
    sleep 1
    nextPrayerName="$(cat "/tmp/nextPrayerTime" | cut -d' ' -f4 )"
    nextPrayerTime="$(cat "/tmp/nextPrayerTime" | cut -d' ' -f5 )"
    h=$(echo $nextPrayerTime|cut -d: -f1 )
    m=$(echo $nextPrayerTime|cut -d: -f2 )
    s=$(echo $nextPrayerTime|cut -d: -f3 )
    if [[ -z "$h" ]] || [[ -z "$m" ]] || [[ -z "$h" ]] ; then
        code=$(ping -c 1 8.8.8.8 2>&1 |grep unreachable >/dev/null; echo $? )
        (( code == 0 )) && {
            >&2 echo "PrayerTime: waiting for network..."
            sleep 30
            continue
        }
        >&2 echo "PrayerTime: getting data..."
        CURL 'https://www.islamicfinder.org/' \
        |sed -n -e '/Upcoming Prayer/{N;N;N;N;N;N;N;s/<[^>]*>//g;s/\s\s*/ /g;p}' \
        >| "/tmp/nextPrayerTime"
        continue
    fi
    if (( $s > 0 )) ;  then
            s=$((s-1))
        elif (( $m > 0)) ; then
            m=$((m-1))
            s=59
        elif (( $h > 0)) ; then
            h=$((h-1))
            m=59
            s=59
        else
            dunstify -u critical -r "$msgId" "Prayer Time " "its time for Salat Al $nextPrayerName"
            CURL 'https://www.islamicfinder.org/' \
            |sed -n -e '/Upcoming Prayer/{N;N;N;N;N;N;N;s/<[^>]*>//g;s/\s\s*/ /g;p}' \
            >| "/tmp/nextPrayerTime"
            continue
    fi
    echo " Upcoming Prayer $nextPrayerName $h:$m:$s" >| "/tmp/nextPrayerTime"
done
