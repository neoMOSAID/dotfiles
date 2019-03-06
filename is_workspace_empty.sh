#!/bin/bash
WINDOWS=$(xdotool search --all --onlyvisible --desktop $(xprop -notype -root _NET_CURRENT_DESKTOP | cut -c 24-) "" 2>/dev/null)
NUM=$(echo "$WINDOWS" | wc -c)
if (( $NUM > 1 ))
    then echo 1
    else echo 0
fi
