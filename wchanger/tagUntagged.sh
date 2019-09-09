#!/usr/bin/bash


python wchangerDB.py untagged |
sed 's@^.*ind.*$@@g' |
sed 's@^.*dir 1.*$@@g' |
sed 's@^.*dir 2.*$@@g' |
sed 's@^.*dir 3.*$@@g' |
sed 's@^.*dir 4.*$@@g' |
sed 's@^.*dir 5.*$@@g' |
sed 's@^.*dir 6.*$@@g' |
sed '/^$/d' >|ll



#data=$(
#    python wchangerDB.py untagged \
#    |grep --color=never 38338 \
#    |sed -E 's@^.*wallhaven-(.*)\..*$@\1@g'
#)
#while read -r l ; do
#        python wchangerDB.py addwtag 38338   "$l"
#        python wchangerDB.py addwtag 182     "$l"
#        python wchangerDB.py addwtag 222     "$l"
#        python wchangerDB.py addwtag 167     "$l"
#        python wchangerDB.py addwtag 355     "$l"
#        python wchangerDB.py addwtag 37932   "$l"
#done <<< "$data"
#


#data=$(
#python wchangerDB.py untagged \
#    |sed -E 's@^.*wallhaven-(.*)\..*$@\1@g'
#)
#number='^[0-9]+$'
#N=$(echo "$data"|wc -l)
#k=1
#while read -r i ; do
#    echo ">>$k/$N : $i<<"
#    if [[ "$i" =~ $number ]] ;
#    then
#        k=$((k+1))
#        continue
#    else
#        ./getWallhaven.sh g "$i" tags verbose "" ""
#    fi
#    k=$((k+1))
#    sleep 7
#done <<< "$data"
#

#
#data=$(
#    python wchangerDB.py uncategorised \
#    |sed -E 's@^.*wallhaven-(.*)\..*$@\1@g'
#)
#N=$(echo "$data"|wc -l)
#k=1
#while read -r i ; do
#    echo ">>$k/$N : $i<<"
#    python wchangerDB.py fixcategory "$i" "s"
#    k=$((k+1))
#done <<< "$data"
