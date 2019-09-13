#!/bin/bash
python wchangerDB.py getall >| /tmp/chwlpAll
cat /tmp/chwlpAll|
xargs -d '\n' identify -format '%[basename]:%w:%h\n' |
awk -F: '{
    a=$1
    a=substr(a,11)
    printf("\"%s\",\"%d\",\"%d\"\n",a,$2,$3)
}' >| /tmp/dimensions.csv

