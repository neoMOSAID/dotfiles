#!/bin/bash
file="${HOME}/.i3/conky/fetchscreen"
echo '
use_xft yes
xftfont MyriadPro:size=12
xftalpha 0.8
text_buffer_size 4096
draw_graph_borders no
update_interval 1
background no
total_run_times 0

own_window yes
own_window_type conky
own_window_type override
own_window_hints undecorated,below,sticky,skip_taskbar,skip_pager
own_window_class Conky
own_window_argb_visual yes
own_window_transparent yes

double_buffer yes
draw_shades no
draw_outline no
draw_borders no
default_color FFFFFF

alignment top_left
gap_x 10
gap_y 60

uppercase no
override_utf8_locale yes

own_window_argb_value 0
own_window_colour EF2929
minimum_size 500 0
TEXT
' >| "${file}"
#echo '${if_match "${exec cat /tmp/my_i3_ws}" == "1" }\' >> "$file"
# echo '${if_match "${exec  /home/mosaid/.i3/is_workspace_empty.sh}" == "0" }\' >> "$file"
screenfetch -N >> "$file"
#echo '${endif}' >> "$file"
#echo '${endif}' >> "$file"


