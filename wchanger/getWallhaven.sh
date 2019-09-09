#!/bin/bash

wallhavenP="$(dirname $(realpath "$0") )/wchangerDB.py"
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

(( ${#@} <= 3 )) && {
    >&2 echo "program requires at least 3 args"
    exit
}

arg_1="$1"          #[sdm],g,adddesc
arg_2="$2"          #squery
arg_3="$3"          #bulk,url,tags
arg_4="$4"          #quiet,verbose
arg_5="$5"          #page number
arg_6="$6"          #force

APIKEY="$(cat "$(dirname $(realpath "$0") )/apikey" )"
httpHeader="X-API-Key: $APIKEY"

function gettags(){
    [[ "$arg_4" == "verbose" ]] && >&2 printf "\033[1;31mgetting tags...\033[0m\n"
    l=$(cat "$tmpfile" | jq -r ".data.tags|length")
    [[ -z "$l" ]] && return
    for (( i=0 ; i< $l ; i++ )) ; do
        id=$(cat "$tmpfile" | jq -r ".data.tags[$i].id")
        name=$(cat "$tmpfile" | jq -r ".data.tags[$i].name")
        alias=$(cat "$tmpfile" | jq -r ".data.tags[$i].alias")
        purity=$(cat "$tmpfile" | jq -r ".data.tags[$i].purity")
        case "$purity" in
            sfw) mycategory=d ;;
            nsfw) mycategory=s ;;
            sketchy) mycategory=m ;;
        esac
        [[ "$arg_4" == "verbose" ]] && >&2 echo "$name"
        python "$wallhavenP" adddesc "$id" "$name" "$alias" "$mycategory"
        python "$wallhavenP" addwtag "$id" "$arg_2"
    done
}

function init_f(){
    case "$arg_1" in
        d) FILTER=100 ;;
        m) FILTER=010 ;;
        s) FILTER=001 ;;
    sm|ms) FILTER=011 ;;
    sd|ds) FILTER=101 ;;
    dm|md) FILTER=110 ;;
    dsm|dms|mds|msd|smd|sdm) FILTER=111 ;;
    esac
    LOCATION="${HOME}/Pictures/wallhaven/.ind/s-444/"
    [[ "$arg_1" == g ]] && LOCATION="${HOME}/Pictures/wallhaven/.ind/fetched/"
    [[ "$arg_1" == d ]] && LOCATION="${HOME}/Pictures/wallhaven/d-333/"

    [[ "$arg_1" != "g" ]] && LOCATION+="$arg_2"
    DELETEDLOCATION="${LOCATION}-deleted"
    [[ ! -d "$LOCATION" ]] && mkdir -p "$LOCATION"
    cd "$LOCATION" || exit

    number='^[0-9]+$'
    if [[ "$arg_2" =~ $number ]]
        then squery="id:$arg_2"
        else squery=$arg_2
    fi
    if [[ "$arg_1" == "g" ]]
        then
            [[ "$arg_4" == "verbose" ]] && >&2 echo "fetching $arg_2"
            rm -f "$tmpfile" 2>/dev/null
            wget -c -q -O "$tmpfile" --header="$httpHeader" "$wAPI/w/$arg_2"
            gettags
            [[ "$arg_3" == tags ]] && exit
        else
            [[ "$arg_4" == "verbose" ]] && >&2 echo "searching $arg_2"
            s1="search?page=1&categories=101&purity=$FILTER&"
            s1+="sorting=random&order=desc&q=$squery"
            [[ "$arg_3" == url ]] && {
                echo "https://wallhaven.cc/$s1"
                exit
            }
            rm -f "$tmpfile" 2>/dev/null
            wget -c -q -O "$tmpfile" --header="$httpHeader" "$wAPI/$s1"
    fi
    echo "geting Wallpaper..." >| "$logfile"
}

function downloadit_f(){
    if [[ "$arg_1" == g ]] && [[ "$purity" == sfw ]] ; then
        LOCATION="${HOME}/Pictures/wallhaven/fetched/"
        [[ ! -d "$LOCATION" ]] && mkdir -p "$LOCATION"
        cd "$LOCATION" || exit
    fi
    wget -c -q "$imgURL"
    if [[ -f "$PWD/$imgNAME" ]] ; then
        touch "$PWD/$imgNAME"
        echo "$PWD/$imgNAME"
        [[ "$arg_4" == "verbose" ]] && >&2 echo "$imgNAME: new"
    fi
    python "$wallhavenP" add "$imgID" "${PWD##*/}" "$PWD/$imgNAME"
    echo "new" >| "$logfile"
    case "$purity" in
        sfw) mycategory=d ;;
        nsfw) mycategory=s ;;
        sketchy) mycategory=m ;;
    esac
    python "$wallhavenP" fixcategory "$imgID" "$mycategory"
}

function getFile_f(){
    downloaded="$(python "$wallhavenP" downloaded "$imgID" )"
    if (( $downloaded == 1 ))
        then
            FILE="$(python "$wallhavenP" get "$imgID" )"
            if [[ "$arg_6" == force ]] && [[ ! -f "$FILE" ]] ; then
                LOCATION="$DELETEDLOCATION"
                [[ ! -d "$DELETEDLOCATION" ]] && mkdir -p "$DELETEDLOCATION"
                cd "$DELETEDLOCATION" || exit
                FILE=$(downloadit_f)
            fi
        else
            FILE=$(downloadit_f)
    fi
    echo "$FILE"
}


function adddesc_f(){
    tag=$arg_2
    [[ "$arg_4" == "verbose" ]] && >&2  echo "adding tag..."
    rm -f "$desctmpfile" 2>/dev/null
    wget -c -q -O "$desctmpfile" --header="$httpHeader" "$wAPI/tag/$tag"
    [[ "$arg_4" == debug ]] && {
        cat "$desctmpfile"
        exit
    }
    name=$(cat "$desctmpfile" | jq -r ".data.name" 2>/dev/null )
    alias=$(cat "$desctmpfile" | jq -r ".data.alias" 2>/dev/null )
    purity=$(cat "$desctmpfile" | jq -r ".data.purity" 2>/dev/null )
    case "$purity" in
        sfw) mycategory=d ;;
        nsfw) mycategory=s ;;
        sketchy) mycategory=m ;;
    esac
    [[ -z "$name" ]] && {
        [[ "$arg_4" == "verbose" ]] && >&2 echo "Error: empty tag"
        exit
    }
    python "$wallhavenP" adddesc "$tag" "$name" "$alias" "$mycategory"
}

[[ "$arg_1" == "adddesc" ]] && {
    number='^[0-9]+$'
    if [[ "$arg_2" =~ $number ]]
        then
            adddesc_f
        else
            [[ "$arg_4" == "verbose" ]] && >&2 echo "$arg_2 not a tag id"
    fi
    exit
}

init_f  "$@"

[[ "$arg_1" == g ]] && {
    imgURL=$(jq -r ".data.path" "$tmpfile" )
    imgNAME="$(basename "$imgURL")"
    imgID=$(jq -r ".data.id" "$tmpfile" )
    purity=$(jq -r ".data.purity" "$tmpfile" )
    getFile_f
    exit
}

if [[ "$arg_3" == "bulk" ]]
    then
        lastpage=$(jq -r ".meta.last_page" "$tmpfile" )
        if [[ -z "$arg_5" ]] ; then
            arg_5=1
        fi
        for (( i=$arg_5 ; i<=$lastpage ; i++ )) ; do
            s1="search?page=$i&categories=101&purity=$FILTER&"
            s1+="sorting=date_added&order=desc&q=$squery"
            echo "page $i/$lastpage"
            rm -f "$tmpfile" 2>/dev/null
            wget -c -q -O "$tmpfile" --header="$httpHeader" "$wAPI/$s1"
            N=$(jq -r ".data|length" "$tmpfile" )
            for (( j=0 ; j < $N ; j++ )) ; do
                echo "      $((j+1))/$N"
                echo -en "\e[1A"
                imgURL=$(jq -r ".data[$j].path" "$tmpfile" )
                imgID=$(jq -r ".data[$j].id" "$tmpfile" )
                purity=$(jq -r ".data[$j].purity" "$tmpfile" )
                imgNAME="$(basename "$imgURL")"
                getFile_f
            done
            echo
        done
    else
        imgURL=$(jq -r ".data[0].path" "$tmpfile" )
        imgID=$(jq -r ".data[0].id" "$tmpfile" )
        purity=$(jq -r ".data[0].purity" "$tmpfile" )
        imgNAME="$(basename "$imgURL")"
        getFile_f
fi

