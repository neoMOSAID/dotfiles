#!/bin/bash
lxterminal -e "locate /home /run/media |fzf > /tmp/mylocate_Data"

sleep 0.4
while [[ -n "$(pidof fzf)" ]] ; do
    sleep 0.4
done

file="$(cat /tmp/mylocate_Data )"
if [[ -z "$file" ]] ; then exit ; fi
mimetype=$(file  --dereference --brief --mime-type  "$file" )

case "$mimetype" in
    inode/directory)            lxterminal -e ranger "$file" ;;
    image/gif)                  viewnior "$file" & disown ;;
    image/*)                    feh "$file" & disown ;;
    text/* | */xml)             lxterminal -e vim "$file"  ;;
    video/* | audio/*)          mpv --force-window=yes  --really-quiet --loop "$file" & disown ;;
    application/pdf)            okular "$file" & disown ;;
    application/octet-stream)
            if [[ "${file#*.}" == "MP3" ]]
                then
                    mpv --really-quiet --loop "$file" & disown
            fi
esac
