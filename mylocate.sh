#!/bin/bash
lxterminal -e "locate /home /run/media |fzf >| ~/.mylocateData"

sleep 0.4
while [[ "$(pidof fzf)" != "" ]] ; do
    sleep 0.4
done
file="$(cat ~/.mylocateData)"
if [[ -z "$file" ]] ; then exit ; fi
mimetype=$(file  --dereference --brief --mime-type  "$file" )
echo "$mimetype"
echo "$mimetype" >> ~/.mylocateDataLog
echo "$file" >> ~/.mylocateDataLog
case "$mimetype" in
    inode/directory)            lxterminal -e bicon.bin ranger "$file" ;;
    image/gif)                  viewnior "$file" & disown ;;
    image/*)                    feh "$file" & disown ;;
    text/* | */xml)             lxterminal -e vim "$file"  ;;
    video/* | audio/*)          mpv --really-quiet --loop "$file" & disown ;;
    application/pdf)            okular "$file" & disown ;;
    application/octet-stream)
                                if [[ "${file#*.}" == "MP3" ]]
                                    then
                                        mpv --really-quiet --loop "$file" & disown
                                fi
                                ;;
    #*)                   #       lxterminal -e bicon.bin ranger --selectfile="$file" ;;
esac


