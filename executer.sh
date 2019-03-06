#!/bin/bash
file="$1"
mimetype=$( file  --dereference --brief --mime-type  "$file" )
case "$mimetype" in
    inode/directory)        ranger "$file" ;;
    image/* )               feh "$file" ;;
    text/* | */xml)         vim "$file"  ;;
    video/* | audio/*)      mpv --really-quiet "$file" ;;
    application/pdf)        okular "$file" ;;
esac

