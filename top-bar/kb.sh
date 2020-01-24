xkb-switch
[[ -z "$BLOCK_BUTTON" ]] && exit
if (( $BLOCK_BUTTON == 3 )) ; then
  nohup onboard  </dev/null >/dev/null 2>&1 &
  exit
fi
if (( $BLOCK_BUTTON == 1 )) ; then
  if [[ `xkb-switch` == fr ]]
      then  xkb-switch -s ar
            pkill -RTMIN+12 i3blocks
      else  xkb-switch -s fr
            pkill -RTMIN+12 i3blocks
  fi
fi

