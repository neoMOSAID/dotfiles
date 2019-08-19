#!/bin/bash
cmd="$1"
arg="$2"
[[ "$cmd" == m1 ]] && [[ -z $arg ]] && {
 echo "
    1 : mariam
    2 : alanbiaa
    3 : al choarae
    4 : Annour
    5 : Al hajj
"
exit
}
touch /tmp/cmd_trigger_tr
echo "$cmd" > /tmp/cmd_trigger_cmd
echo "$arg" > /tmp/cmd_trigger_arg


