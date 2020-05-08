#!/bin/bash
msgId=11122
echo x
function chwlp_show(){
    ~/.config/wchanger/wchanger.sh cwt|
    sed '1d;3d'
}

case $BLOCK_BUTTON in
    1) ~/.config/wchanger/wchanger.sh o ;;
    3) i3-msg 'kill' ;;
    4) dunstify -u normal -r "$msgId"  "$(chwlp_show)" ;;
    5) dunstify -u normal -r "$msgId"  "$(chwlp_show)" ;;
esac

