#!/bin/bash
file="$1"

SCRIPTNAME="${0##*/}"

err() {
    printf >&2 "$SCRIPTNAME: $*\n"
        exit 1
}

file="$(readlink -f "$file")"
mkdir "$file-extDir"
dir="$file-extDir"
case "$file" in
        *.tar.bz2)   tar xjf     "$file"  -C "$dir"    ;;
        *.tar.gz)    tar xzf     "$file"  -C "$dir"    ;;
        *.bz2)       bunzip2     "$file"               ;;
        *.rar)       unrar e     "$file"               ;;
        *.gz)        gunzip      "$file"               ;;
        *.tar)       tar xf      "$file"  -C "$dir"    ;;
        *.tbz2)      tar xjf     "$file"  -C "$dir"    ;;
        *.tgz)       tar xzf     "$file"  -C "$dir"    ;;
        *.zip)       unzip       "$file"  -d "$dir"    ;;
        *.Z)         uncompress  "$file"               ;;
        *.7z)        7z x        "$file"  -o"$dir"    ;;
        *)           echo "'$file' cannot be extracted by $SCRIPTNAME" ;;
esac

