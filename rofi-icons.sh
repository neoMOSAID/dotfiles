options='-columns 6 -width 100 -lines 20 -bw 2 -yoffset -20 -location 1'

selected=$(\
    cat ~/.i3/icon-list.txt \
    | rofi -dmenu -i -markup-rows \
    -p "Select icon: ")

# exit if nothing is selected
[[ -z $selected ]] && exit

echo -ne $(echo "$selected" |\
    awk -F';' -v RS='>' '
    NR==2{sub("&#x","",$1);print "\\u" $1;exit}'
    ) |  xclip -selection clipboard

