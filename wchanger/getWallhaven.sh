#!/bin/bash

phpscript="$(dirname $(realpath "$0") )/db.php"
logfile="/tmp/wchanger_wlog"
tmpfile="/tmp/getwallhaven_tmpfile"
desctmpfile="/tmp/getwallhaven_desc_tmpfile"
wAPI="https://wallhaven.cc/api/v1"

scriptname=$( basename "$0" )
is_running=$( pgrep  -f -c "$scriptname" )
if (( $is_running > 2 )) ; then
    >&2 echo $scriptname is running $is_running.
    exit 0
fi

APIKEY="$(cat "$(dirname $(realpath "$0") )/apikey" )"
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

    number='^[0-9]+$'
    if [[ "$2" =~ $number ]]
        then squery="id:$2"
        else squery=$2
    fi
    if [[ "$1" == "g" ]]
        then
            #>&2 echo "fetching $2"
            rm -f "$tmpfile" 2>/dev/null
            wget -c -q -O "$tmpfile" --header="$httpHeader" "$wAPI/w/$2"
        else
            #>&2 echo "searching $2"
            s1="search?page=1&categories=101&purity=$FILTER&"
            s1+="sorting=random&order=desc&q=$squery"
            rm -f "$tmpfile" 2>/dev/null
            wget -c -q -O "$tmpfile" --header="$httpHeader" "$wAPI/$s1"
    fi
    echo "geting Wallpaper..." >| "$logfile"
}

function downloadit_f(){
    if [[ "$(php -f "$phpscript" f=downloaded "$imgID" )" == "0" ]]
        then
            wget -c -q "$imgURL"
            if [[ -f "$PWD/$imgNAME" ]] ; then
                touch "$PWD/$imgNAME"
                echo "$PWD/$imgNAME"
                >&2 echo "$imgNAME: new"
            fi
            php -f "$phpscript" f=add "$imgID" "${PWD##*/}" "$PWD/$imgNAME"
            echo "new" >| "$logfile"
        else
            >&2 echo "$imgID : already downloaded"
            echo "already downloaded" >| "$logfile"
            php -f "$phpscript" f=get "$imgID"
    fi

    case "$purity" in
            sfw) mycategory=d ;;
           nsfw) mycategory=s ;;
        sketchy) mycategory=m ;;
    esac
    php -f "$phpscript" f=fixcategory "$imgID" "$mycategory"
    #>&2 echo "$imgID : category $mycategory"
}

function adddesc_f(){
    tag=$1
    #>&2  echo "adding tag..."
    rm -f "$desctmpfile" 2>/dev/null
    wget -c -q -O "$desctmpfile" --header="$httpHeader" "$wAPI/tag/$tag"
    [[ "$2" == v ]] && {
        cat "$desctmpfile"
        exit
    }
    name=$(cat "$desctmpfile" | jq -r ".data.name" 2>/dev/null )
    alias=$(cat "$desctmpfile" | jq -r ".data.alias" 2>/dev/null )
    [[ -z "$name" ]] && {
        >&2 echo "Error: empty tag"
        exit
    }
    php -f "$phpscript" f=adddesc "$tag" "$name" "$alias"
}

function settings_f(){
    rm -f "$tmpfile" 2>/dev/null
    wget -c -q -O "$tmpfile" --header="$httpHeader" "$wAPIsettings?$APIKEY"
    #php -f "$phpscript" f=adddesc "$2" "$desc" >/dev/null 2>&1
    cat "$tmpfile" | python -m json.tool
}

[[ "$1" == "adddesc" ]] && {
    number='^[0-9]+$'
    if [[ "$2" =~ $number ]]
        then adddesc_f "$2" "$3"
        else >&2 echo not an id
    fi
    exit
}

init_f  "$@"

case "$1" in
        g)
            imgURL=$(jq -r ".data.path" "$tmpfile" )
            imgNAME="$(basename "$imgURL")"
            imgID=$(jq -r ".data.id" "$tmpfile" )
            purity=$(jq -r ".data.purity" "$tmpfile" )
            downloadit_f 0 "$1" ;;
        *)
            if [[ "$3" == "bulk" ]]
                then
                    lastpage=$(jq -r ".meta.last_page" "$tmpfile" )
                    for (( i=1;i<=$lastpage; i++ )) ; do
                        s1="search?page=$i&categories=101&purity=$FILTER&"
                        s1+="sorting=date_added&order=desc&q=$2"
                        echo "page $i/$lastpage"
                        rm -f "$tmpfile" 2>/dev/null
                        wget -c -q -O "$tmpfile" --header="$httpHeader" "$wAPI$s1"
                        for (( j=1 ; j<=24; j++ )) ; do
                            imgURL=$(jq -r ".data[$j].path" "$tmpfile" )
                            imgID=$(jq -r ".data[$j].id" "$tmpfile" )
                            purity=$(jq -r ".data[$j].purity" "$tmpfile" )
                            imgNAME="$(basename "$imgURL")"
                            downloadit_f $j
                        done
                    done
                else
                    imgURL=$(jq -r ".data[1].path" "$tmpfile" )
                    imgID=$(jq -r ".data[1].id" "$tmpfile" )
                    purity=$(jq -r ".data[1].purity" "$tmpfile" )
                    imgNAME="$(basename "$imgURL")"
                    downloadit_f 1 "$1"
            fi
esac


