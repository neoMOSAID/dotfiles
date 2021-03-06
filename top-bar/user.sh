#!/bin/bash

[[ -t 0 ]] && BLOCK_BUTTON=3
COLOR="#00ffff"
echo "$USER"|awk '{print toupper($_)}'
echo
echo "$COLOR"


# error codes :
# 0 : OK , 100%
# 1 : cancel, esc
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
function themenu(){
    joey="/home/mosaid/OneDrive/OneDrive/linux/scripts2/joeyThePassion.sh"
    txtreader="/run/media/mosaid/My_Data/Documents/myPrograms/text_reader.exe "
    pplay='/home/mosaid/.i3/pplay/play.sh'

    mymenu=( onboard display txtReader joey 6Dif POP tor pplay
        screenshot1 screenshot2 'screenshot (5s delay)' shutdown reboot logout  )
    ch=$( for (( ii=0 ; ii<${#mymenu[@]} ; ii++ )) ; do
        printf "${mymenu[$ii]}\n"
        done |rofi -dmenu -p menu -width -30
    )
    case "$ch" in
        logout)
                        result=$(zenity_progress "logout" )
                        if [[ "$result" == "0" ]] ; then
                            i3-msg exit
                        fi ;;
        shutdown)
                        result=$(zenity_progress "shutdown" )
                        if [[ "$result" == "0" ]] ; then
                            systemctl poweroff
                        fi ;;
        reboot)
                        result=$(zenity_progress "reboot" )
                        if [[ "$result" == "0" ]] ; then
                            systemctl reboot
                        fi ;;
        joey)           "$joey" 1 ;;
        txtReader)      nohup wine "$txtreader"  </dev/null >/dev/null 2>&1 & ;;
        onboard)        nohup onboard  </dev/null >/dev/null 2>&1 & ;;
        tor)            bash /home/mosaid/OneDrive/OneDrive/linux/scripts2/myBash_functions.sh ttor ;;
        pplay)          bash "$pplay" ;;
        screenshot1)    sleep 0.200 ; bash ~/.i3/screenshot.sh 1 >/dev/null ;;
        screenshot2)    sleep 0.200 ; bash ~/.i3/screenshot.sh 2 >/dev/null ;;
        'screenshot (5s delay)') sleep 5.200 ; bash ~/.i3/screenshot.sh 2 >/dev/null ;;
        display)        bash ~/.i3/display.sh default >/dev/null ;;
        POP)
            cd "/home/mosaid/Documents/Prince Of Persia - The Warrior Within"
            i3-msg "workspace 11"
            nohup wine POP2.EXE </dev/null >/dev/null 2>&1 &  ;;
        6Dif)
            cd "/run/media/mosaid/My_Data/documents/swf"
            i3-msg "workspace 11"
            wine "$dif6Cmd"
            nohup wine FlashPlayer.exe 6Diff.swf  </dev/null >/dev/null 2>&1 & ;;
    esac
}

[[ -z "$BLOCK_BUTTON" ]] && [[ "$1" == "menu" ]] && BLOCK_BUTTON=1
msgId=11112
case "$BLOCK_BUTTON" in
    4)
        msg=$(~/.config/wchanger/wchanger.sh - 2>&1)
        dunstify -u low -r "$msgId"  "wchanger prev" "$msg"
        exit
    ;;
    5)
        msg=$(~/.config/wchanger/wchanger.sh  2>&1)
        dunstify -u low -r "$msgId"  "wchanger next" "$msg"
        exit
    ;;
    1) themenu
       exit
    ;;
    3)
        ~/.config/wchanger/wchanger.sh  x
        exit
esac

