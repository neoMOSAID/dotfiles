#!/bin/bash

function hdmiOn(){
    xrandr \
        --output eDP1 \
        --primary \
        --mode    1920x1080 \
        --pos     0x0 \
        --rotate  normal \
        --output HDMI1 \
        --mode    1920x1080i \
        --pos     1920x0 \
        --rotate  normal \
        --output VGA1 --off \
        --output VIRTUAL1 --off \
        --output DP1 --off
}

function hdmiOff(){
    xrandr \
        --output VGA1     --off \
        --output DP1      --off \
        --output HDMI1    --off \
        --output eDP1 \
        --primary \
        --mode    1920x1080 \
        --pos     0x0 \
        --rotate  normal
}

case "$1" in
    extended)
                hdmiOn
                notify-send "Display: Extended "
                bash /home/mosaid/OneDrive/OneDrive/linux/touchpadSettings.sh
                #pacmd set-card-profile alsa_card.pci-0000_00_1b.0 output:hdmi-stereo+input:analog-stereo
                #pacmd set-default-sink combined
                ;;
    default)
                hdmiOff
                notify-send "Display: Default"
                #set-card-profile alsa_card.pci-0000_00_1b.0 output:analog-stereo
                ;;
    mirrored)
                xrandr --output eDP1 --mode 1920x1080 --output HDMI1  --same-as eDP1
                notify-send "Display: mirrored"
                ;;
esac

#if `xrandr |grep "HDMI1 connected" >/dev/null`




