#!/bin/bash
dir="$1"
#c=s
for line in `ls -1 --color=never "$dir" ` ; do
    id=${line#*-}
    id=${id%.*}
    dd=${dir##*/}
    php -f db.php f=add "$id" "$dd" "$dir/$line"
    php -f db.php f=fixcategory "$id" "s"
done
