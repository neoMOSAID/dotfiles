
SCRIPTPATH="${HOME}/.i3/wchanger"
wallhavenP="$SCRIPTPATH/wchangerDB.py"
wAPI="https://wallhaven.cc/api/v1"
APIKEY="$(cat "$SCRIPTPATH/apikey" )"
httpHeader="X-API-Key: $APIKEY"
tmpfile="/tmp/getwallhaven_tmpfile_tag"

rm -f "$tmpfile" 2>/dev/null
wget -c -q -O "$tmpfile" --header="$httpHeader" "$wAPI/w/$1"

printf "\033[1;31mgetting tags...\033[0m\n"
l=$(jq -r ".data.tags|length" "$tmpfile")

[[ -z "$l" ]] && exit

for (( i=0 ; i< $l ; i++ )) ; do
    id=$(jq -r ".data.tags[$i].id" "$tmpfile")
    name=$(jq -r ".data.tags[$i].name" "$tmpfile" )
    alias=$(jq -r ".data.tags[$i].alias" "$tmpfile" )
    purity=$(jq -r ".data.tags[$i].purity" "$tmpfile" )
    case "$purity" in
        sfw) mycategory=d ;;
        nsfw) mycategory=s ;;
        sketchy) mycategory=m ;;
    esac
    [[ "$arg_4" == "verbose" ]] && >&2 echo "$name"
    python "$wallhavenP" createtag "$id" "$name" "$alias" "$mycategory"
    python "$wallhavenP" addwtag "$id" "$1"
    echo "$name"
done

