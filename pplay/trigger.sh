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
echo "$cmd" >| "${HOME}/.i3/pplay/cmd"
echo "$arg" >| "${HOME}/.i3/pplay/arg"
echo "1"    >| "${HOME}/.i3/pplay/tr"


