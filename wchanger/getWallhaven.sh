#!/bin/bash

phpscript="$(dirname "$0")/db.php"
logfile="${HOME}/.i3/wallpaper/wlog"

scriptname=$( basename "$0" )
is_running=$( pgrep  -f -c "$scriptname" )
if (( $is_running > 2 )) ; then
    >&2 echo $scriptname is running $is_running.
    exit 0
fi

APIKEY="$(cat "$(dirname "$0")/apikey" )"
httpHeader="X-API-Key: $APIKEY"

function init_f(){
    case "$1" in
        m) #moderate
            FILTER=010
            LOCATION="${HOME}/Pictures/wallhaven/.ind/m-222/"
            ;;
        s) #indecent
            FILTER=111
            LOCATION="${HOME}/Pictures/wallhaven/.ind/s-222/"
            ;;
        g)
            LOCATION="${HOME}/Pictures/wallhaven/.ind/fetched/"
            ;;
        *) #decent
            FILTER=100
            LOCATION="${HOME}/Pictures/wallhaven/d-222/"
    esac

    [[ "$1" != "g" ]] && LOCATION+="$2"
    [[ ! -d "$LOCATION" ]] && mkdir -p "$LOCATION"
    cd "$LOCATION" || exit

    rm tmp 2>/dev/null
    if [[ "$1" == "g" ]]
        then
            >&2 echo " fetching $2 "
            wget -c -q -O tmp --header="$httpHeader" "https://wallhaven.cc/api/v1/w/$2"
        else
            s1="search?page=1&categories=101&purity=$FILTER&"
            s1+="sorting=random&order=desc&q=$2"
            >&2 echo " searching $2 "
            wget -c -q -O tmp --header="$httpHeader" "https://wallhaven.cc/api/v1/$s1"
    fi
    echo "geting Wallpaper..." >| "$logfile"
}

function downloadit_f(){


    if [[ "$(php -f "$phpscript" f=downloaded "$imgID" )" == "0" ]]
        then
            wget -c -q "$imgURL"
            touch "$PWD/wallhaven-$imgID.jpg"
            echo "$PWD/wallhaven-$imgID.jpg"
            >&2 echo "          $imgID: new"
            php -f "$phpscript" f=add "$imgID" "${PWD##*/}" "$PWD/wallhaven-$imgID.jpg"
            echo "new" >| "$logfile"
        else
            >&2 echo "              $imgID : already downloaded"
            echo "already downloaded" >| "$logfile"
            php -f "$phpscript" f=get "$imgID"
    fi

    case "$purity" in
            sfw) mycategory=d ;;
           nsfw) mycategory=s ;;
        sketchy) mycategory=m ;;
    esac
    php -f "$phpscript" f=fixcategory "$imgID" "$mycategory"
}

function adddesc_f(){
    rm tmp 2>/dev/null
    wget -c -q -O tmp --header="$httpHeader" "https://wallhaven.cc/api/v1/tag/$1"
    #php -f "$phpscript" f=adddesc "$2" "$desc" >/dev/null 2>&1
    cat tmp | python -m json.tool
}

function settings_f(){
    rm tmp 2>/dev/null
    wget -c -q -O tmp --header="$httpHeader" "https://wallhaven.cc/api/v1/settings?$APIKEY"
    #php -f "$phpscript" f=adddesc "$2" "$desc" >/dev/null 2>&1
    cat tmp | python -m json.tool
}

init_f  "$@"

case "$1" in
        g)
            imgURL=$(jq -r ".data.path" tmp)
            imgID=$(jq -r ".data.id" tmp)
            purity=$(jq -r ".data.purity" tmp)
            downloadit_f 0 ;;
  adddesc)  adddesc_f  "38338" ;;
 settings)  settings_f ;;
       * )
            if [[ "$3" == "bulk" ]]
                then
                    lastpage=$(jq -r ".meta.last_page" tmp)
                    for (( i=1;i<=$lastpage; i++ )) ; do
                        s1="search?page=$i&categories=101&purity=$FILTER&"
                        s1+="sorting=date_added&order=desc&q=$2"
                        echo "page $i/$lastpage"
                        rm tmp 2>/dev/null
                        wget -c -q -O tmp --header="$httpHeader" "https://wallhaven.cc/api/v1/$s1"
                        for (( j=1 ; j<=24; j++ )) ; do
                            imgURL=$(jq -r ".data[$1].path" tmp)
                            imgID=$(jq -r ".data[$1].id" tmp)
                            purity=$(jq -r ".data[$1].purity" tmp)
                            downloadit_f $j
                        done
                    done
                else
                    imgURL=$(jq -r ".data[1].path" tmp)
                    imgID=$(jq -r ".data[1].id" tmp)
                    purity=$(jq -r ".data[1].purity" tmp)
                    downloadit_f 1
            fi
esac


