#!/bin/bash
function CURL (){
    userAgent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:48.0) "
    userAgent+="Gecko/20100101 Firefox/48.0"
    curl -s -A "$userAgent" "$@"
}

CURL 'https://www.islamicfinder.org/' \
|sed -n -e '/Upcoming Prayer/{N;N;N;N;N;N;N;s/<[^>]*>//g;s/\s\s*/ /g;p}'
