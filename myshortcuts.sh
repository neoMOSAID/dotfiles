#!/bin/bash
file="${HOME}/.i3/conky/shortcuts"
echo "use_xft yes
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
own_window_transparent no

double_buffer yes
draw_shades no
draw_outline no
draw_borders no
default_color FFFFFF

alignment top_right
gap_x 10
gap_y 60

uppercase no
override_utf8_locale yes

own_window_argb_value 0
own_window_colour 000000
minimum_size 500 0
TEXT" >| "${file}"
echo '${if_match "${exec cat /home/mosaid/.i3/.ws}" == "1" }\' >> "$file"
echo '${if_match "${exec  /home/mosaid/.i3/is_workspace_empty.sh}" == "0" }\' >> "$file"
echo '\
${color green}\
${voffset -10}\
_______________\
${voffset +10}\
 .: i3wm shortcuts :. \
${voffset -10}\
_______________\
${voffset +10}\
${color lightblue}\
' >> "$file"
cat ~/.i3/config | grep ^binds\
    | sed 's/bindsym//g;
           s/exec --no-startup-id//g;
           s/$mod/WIN/g;
           s/mod1/ALT/g;
           s@~/OneDrive/OneDrive/linux/scripts0/@@g;
           s@~/OneDrive/OneDrive/linux/scripts1/@@g;
           s@~/OneDrive/OneDrive/linux/scripts2/@@g;
           s/^[ \t]*//g' \
    |awk '{
            printf("%s",$1);
            $1="";
            if (length()>39){
                gsub(substr($0,34,39),"...")
            }
            printf("${goto 230}")
            printf("%s\n",substr($0,0,39));
            }' \
     >> "$file"
echo '${endif}' >> "$file"
echo '${endif}' >> "$file"


















#                |awk 'BEGIN {
#                printf("<table>\n");
#                printf("\t<tr>\n");
#                printf("\t\t<th>key</th>\n");
#                printf("\t\t<th>command</th>\n");
#                printf("\t</tr>\n");
#            }
#        {
#            printf("\t<tr>\n")
#            printf("\t\t<td>%s</td>\n",$1);
#            printf("\t\t<td>");
#            for(i=2;i<=NF;i++)  printf("%s ", $i);
#                printf("</td>\n");
#            }
#    END {
#    printf("</table>\n");
#    printf("<style>\n\
#        td, th {\n\
#        text-align:center;\n\
#        border: 2px solid black;\n\
#    }\n\
#    </style>\n"\
#    );
#}'
#
#
