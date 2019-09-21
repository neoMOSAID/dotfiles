
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


data=$(
python wchangerDB.py untagged \
    |sed -E 's@^.*wallhaven-(.*)\..*$@\1@g'
)
number='^[0-9]+$'
N=$(echo "$data"|wc -l)
k=1
while read -r i ; do
    echo ">>$k/$N : $i<<"
    if [[ "$i" =~ $number ]] ;
    then
        k=$((k+1))
        continue
    else
        ./tag.sh "$i"
    fi
    k=$((k+1))
    sleep 7
done <<< "$data"


