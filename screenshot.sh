#!/bin/bash
filename="screenshot-$(date '+%Y-%m-%d--%H-%M-%S').png"
scrot "/tmp/$filename"
if [[ "$1" == "1" ]]
    then
          convert "/tmp/$filename" -crop 1920x1080+0+0 "/tmp/$filename"
    else
          convert "/tmp/$filename" -crop 1920x1080+1920+0 "/tmp/$filename"
fi
mv "/tmp/$filename" "/home/mosaid/Pictures/$filename"
mplayer ~/.i3/Nikon.ogg

