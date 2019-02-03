#pkill -RTMIN+10 i3blocks
xkb-switch
if (( $BLOCK_BUTTON == 3 )) ; then
  nohup onboard  </dev/null >/dev/null 2>&1 & 
  exit
fi
if (( $BLOCK_BUTTON == 1 )) ; then
  if [[ `xkb-switch` == fr ]] 
      then  xkb-switch -s ar
      else  xkb-switch -s fr
  fi
fi

