#!/bin/bash

function zenity_progress(){
    (
    for ((i=0;i<=60;i++)) do
        echo "$i%"
        echo "# System $1 in $((60-i)) s"
        sleep 1
    done
    ) | zenity --width=300 --title="$USER" \
        --auto-close  --progress
            echo $?
}

case "$1" in
    lock)
        betterlockscreen --lock
        ;;
    logout)
        i3-msg exit
        ;;
    suspend)
        lock && systemctl suspend
        ;;
    hibernate)
        lock && systemctl hibernate
        ;;
    reboot)
        result=$(zenity_progress "logout" )
        if [[ "$result" == "0" ]] ; then
            systemctl reboot
        fi ;;
    shutdown)
        result=$(zenity_progress "logout" )
        if [[ "$result" == "0" ]] ; then
            systemctl poweroff
        fi ;;
    *)
        echo "Usage: $0 {lock|logout|suspend|hibernate|reboot|shutdown}"
        exit 2
esac

exit 0
