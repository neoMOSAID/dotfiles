#!/bin/bash

wallhavenScript="${HOME}/gDrive/gDrive/linux/scripts2/getWallpHaven/getWAllpHaven.sh"
wallhavenPhp="${HOME}/gDrive/gDrive/linux/scripts2/getWallpHaven/db.php"
workspace=$(cat ${HOME}/.i3/.ws )
goto=0
msgId="991050"
cl=0
notexpired=$(php -f "$wallhavenPhp" f=wh_get "expired" )

function _pic_(){
    cat ${HOME}/.fehbg \
    | awk -F\' 'NR==2{print $2}' \
    |xargs echo
}

function _x_(){
    pic=$( _pic_ )
    ans=$(  zenity --width=500 \
        --title="wallpaper changer" \
        --text="remove : \n \'$pic\' ?" \
        --timeout=10 --question; echo $?
    )
    if [[ "$ans" == "0" ]] ; then
        echo "deleting it "
        mv "$pic" "${HOME}/Pictures/trashed"
        pic=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
        number='^[0-9]+$'
        if ! [[ "$pic" =~ $number ]] ; then
            echo not a wallhaven wallpaper
            exit
        fi
        php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
    fi
    exit
}

[[ "$1" == "x" ]] && _x_

is_running=$( pgrep -fc  "$(realpath "$0" )" )
if (( $is_running >= 2 )) ; then
    >&2 echo ${0##*/} is running.
    exit 0
fi

function _printhelp () {
    printf '\033[1;31m\t%-23s\033[1;0m\t%s\n' "$1" "$2"
}

function f_help(){
    printf '\033[01;33m'
    echo "
    multi layred wallpaper changer for i3wm powered by a mysql database,
    each workspace can have up to 4 states,
    with two modes ( default and password protected mode)
    features include (for each workspace ):
        - a single wallpaper
        - a directory of wallpapers (local not wallhaven)
        - a list of favorites wallpapers
        - wallpaper changing paused/unpaused
        - ...
    "
    _printhelp "af|addfav"                     "add current wallpaper to favs"
    _printhelp "al|addlist [id] [name] [c]"    "add list"
    _printhelp "c"                             "current wallpaper path"
    _printhelp "cl"                            "current favsList"
    _printhelp "cm"                            "current mode"
    _printhelp "d|download [id] [c]"           "download image by wallhaven id"
    _printhelp "dim"                           "wallpaper dimensions"
    _printhelp "dir"                           "wallpapers directory"
    _printhelp "fav[sdm]"                      "change favsList"
    _printhelp "fix"                           "change current wallpaper's category"
    _printhelp "g [number]"                    "jump to wallpaper"
    _printhelp "h,help"                        "print this help"
    _printhelp "i|id"                          "current wallpaper's wallhaven id"
    _printhelp "l|list"                        "a montage of the next 50 wallpapers"
    _printhelp "lm"                            "list of available modes"
    _printhelp "o"                             "open current wallpaper in feh"
    _printhelp "ow"                            "open current wallpaper in browser"
    _printhelp "p"                             "enable/disable wallpaper changing"
    _printhelp "r|rm"                          "remove from favs"
    _printhelp "ow"                            "set which wallpaper category to show"
    _printhelp "sp|setpause"                   "set current wallpaper as pause wallpaper"
    _printhelp "sm|setmode"                    "set mode for current workspace"
    _printhelp "u|unexpire"                    "enable password mode"
    _printhelp "url"                           "wallhaven search url"
    _printhelp "" "next wallpaper"
    _printhelp "n" "next wallpaper"
    _printhelp "wlist [sdm]" "print favsLists names"
    _printhelp "zoom" "experimental not working"
    _printhelp "oc" "set ordered c"
    _printhelp "wid" "set web id"
    _printhelp "setpause" "set current wallpaper as pause wallpaper"
    _printhelp "pause" "pause/resume wallpaper changing"
    _printhelp "wopen" "open wallpaper in wallhaven.com"
    _printhelp "x" "remove current wallpaper"
    exit
}

# no args
# print the fav list id
function GETFID(){
    if [[ -z "$notexpired" ]] ; then
        >&2 echo "expire not yet defind (first use?)"
        exit
    fi
    php -f "$wallhavenPhp" f=wh_get "ws${workspace}FID_$notexpired"
}

# $1 : category [sdm]
# $2 : title
function favsList(){
    declare -A arr=()
    while read -r l ; do
        id=${l%%:*}
        name=${l#*:}
        arr[$name]="$id"
    done <<< "$(php -f "$wallhavenPhp" f=getfavlist "${1}" )"
    LIST=$( for k in "${!arr[@]}" ; do
            printf '%02d : %s\n' "${arr[$k]}" "$k"
            done
    )
    ans=$(
     echo "$LIST" \
     | sort \
     |rofi -dmenu -p "$2" -width -60
    )
    ans=${ans#*: }
    ! [[ -z "$ans" ]] && echo "${arr[$ans]}"
}

# $1 : name of the list
# $2 : category of the list
function addFAVLIST(){
    name=$1
    c=$2
    if [[ -z "$c" ]] || [[ -z "$name" ]] ; then
        >&2 echo "name or category not given"
        exit
    fi
    result=$( php -f "$wallhavenPhp" f=addfavlist "$name" "$c" )
    if echo "$result" |grep -w Duplicate >/dev/null
        then echo "$name already exists"
        else echo "list added"
    fi
    exit
}

function printFav(){
    if [[ -z "$1" ]]
        then
            fid=$(GETFID)
            if [[ -z "$fid" ]] ; then
                >&2 echo "no list was chosen"
                exit
            fi
            index=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_lastindex_$fid" )
        else
            msg="select list to print"
            if (( $notexpired == 1 ))
                then fid=$( favsList "sm" "$msg" )
                else fid=$( favsList 'd' "$msg" )
            fi
    fi
    [[ -z "$index" ]] && index=1
    php -f "$wallhavenPhp" f=getfavs "$fid" \
        | sed -n "$index,$"p > /tmp/chwlp_feh_dir_list
    feh --index-info "%u\n" \
        -x -m -W 1920 -H 1080 \
        -E 180 -y 180  \
        -f /tmp/chwlp_feh_dir_list 2> /dev/null
    exit
}

# $1 c
function addFav(){
    pic=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
    number='^[0-9]+$'
    if ! [[ "$pic" =~ $number ]] ; then
        echo not a wallhaven wallpaper
        exit
    fi
    c=$(php -f "$wallhavenPhp" f=getcategorybyname "$pic" )
    [[ -z "$c" ]] && c='*'
    ! [[ -z "$1" ]] && c="$1"
    msg="add it to "
    fid=$( favsList "$c" "$msg" )
    if [[ -z "$fid" ]] ; then
        >&2 echo "no fid"
        exit
    fi
    result=$( php -f "$wallhavenPhp" f=addfav "$fid" "$pic" )
    if echo "$result" |grep -w Duplicate >/dev/null
        then echo $pic already in $fid
             msg="already added"
        else echo "$pic added to list id : $fid"
             msg="added"
    fi
    dunstify -u normal -r "$msgId" "wallpaper changer" "$msg"
    exit
}

function getFIDById(){
    pic="$1"
    LISTS=$( php -f "$wallhavenPhp" f=getfavlistbyname "$pic" )
    ans=$(
        echo "$LISTS" |rofi -dmenu -p "remove it from " -width -60
    )
    if [[ -z "$ans" ]] ; then
        >&2 echo "empty choice"
        exit
    fi
    echo "${ans%:*}"
}

function rmFav(){
    pic=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
    number='^[0-9]+$'
    if ! [[ "$pic" =~ $number ]] ; then
        echo not a wallhaven wallpaper
        exit
    fi
    fid=$( getFIDById "$pic" )
    php -f "$wallhavenPhp" f=rmfav "$fid" "$pic"
}

function unexpire(){
    pass=$( zenity --password --name="wallpaper changer"  --timeout=30)
    result=$( php -f "$wallhavenPhp" f=authenticate "wchanger" "$pass" )
    php -f "$wallhavenPhp" f=wh_set "expired" "$result"
    notexpired=$result
}

function pass_f(){
    if [[ -p /dev/stdout ]]
        then
            read -r -s -p "pass : " pass
            result=$( php -f "$wallhavenPhp" f=authenticate "wchanger" "$pass" )
            printf "$result"
        else
            printf "0"
    fi
}

# $1 [sdm]
# $2 f
function changeFavList(){
    msg="select fav list for workspace $workspace"
    if [[ "$1" != d ]] && [[ $notexpired == "0" ]] ; then
        [[ "$2" != "f" ]] \
        && dunstify -u normal -r "$msgId" "wallpaper changer" "not permitted" \
        && exit
        [[ "$(pass_f)" == 0 ]] && exit
    fi
    c=$1
    fid=$( favsList "$c" "$msg" )
    if [[ -z "$fid" ]] ; then
        >&2 echo "empty choice"
        exit
    fi
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}FID_$notexpired" "$fid"
}

function dirHandler(){
    dir0="/run/media/mosaid/My_Data/images"
    declare -A arr=()
    arr=(
    ["All Images"]="${dir0}/001 images"
    ["Post Apocalyptic Wallpapers"]="${dir0}/collectionWallpapers/Post Apocalyptic Wallpapers"
    ["Nature Wallpapers"]="${dir0}/001 images/Nature Wallpapers"
    ["Islamic Wallpapers"]="${dir0}/Islamic.Wallpapers"
    ["fields"]="${HOME}/Pictures/wallpapers/fields"
    )

    LIST=$( for k in "${!arr[@]}" ; do
                printf '%s\n' "$k"
            done
    )
    ans=$(
        echo "$LIST" |rofi -dmenu -p "ws $workspace wallpapers list" -width -60
    )
    if [[ -z "$ans" ]] ; then
        >&2 echo "empty choice"
        exit
    fi
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}FID_dir_$notexpired"  "${arr[$ans]}"

}

# $1 can be workspace
function setPauseW(){
    ! [[ -z "$1" ]] && [[ "$1" != "f" ]] && workspace=$1
    id=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
    number='^[0-9]+$'
    if ! [[ "$id" =~ $number ]] ; then
        echo not a wallhaven wallpaper
        exit
    fi
    if [[ -z "$notexpired" ]] ; then
        >&2 echo "mode 1  not defind"
        exit
    fi
    if  (( $notexpired == 0 )) && (( $workspace <= 7 ))
        then
            if [[ "$(pass_f)" == "0" ]] ; then
                dunstify -u normal -r "$msgId" "wallpaper changer" "not permitted"
                exit
            fi
    fi
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}_pause_id_$notexpired"  "$id"
    exit
}

function fix_m(){
    pic=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
    number='^[0-9]+$'
    if ! [[ "$pic" =~ $number ]] ; then
        echo not a wallhaven wallpaper
        exit
    fi
    c="$2"
    [[ -z "$c" ]] && c=$( printf "d\nm\ns" \
        |rofi -dmenu -p "$pic category " -width -30 )
    if [[ -z "$c" ]] ; then
        >&2 echo "empty choice"
        exit
    fi
    php -f "$wallhavenPhp" f=fixcategory "$pic" "$c"
    echo "$pic : category = $c"
    exit

}

# $1 : n,p,"",number
# $2 : number of paths to fetch
function getOrdered(){
    category="$(get_ordered_c)"
    if (( $cl == 1 )) ; then
        echo "all available wallpapers in the category : $category"
        exit
    fi
    name="ws${workspace}_lastindex_$category"
    id=$(php -f "$wallhavenPhp" f=wh_get "$name" )
    N=$(php -f "$wallhavenPhp" f=getorderedcount "$category" )
    id=$((id+goto))
    case "$1" in
        ""|+)
            id=$(($id+1))
            if (( $id > $N )) ; then id=1 ; fi
            ;;
        -)
            id=$(($id-1))
            if (( $id <=0 )) ; then id=$N ; fi
            ;;
        *)
            number='^[0-9]+$'
            if [[ "$2" =~ $number ]]
            then id=$2
            fi
    esac
    php -f "$wallhavenPhp" f=wh_set "$name"  "$id"
    limit=1
    ! [[ -z "$2" ]] && limit=$2
    pic="$(php -f "$wallhavenPhp" f=getordered $id $category "$limit" )"
    if [[ -z "$pic" ]] ; then
        >&2 echo "empty pic"
        exit
    fi
    echo "$id/$N"
    echo "$id/$N" >| ~/.i3/wallpaper/wlog
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "${HOME}/.i3/wallpaper/w8.jpg"
    else
        echo "$pic" >> "${HOME}/.i3/wallpaper/errlog"
        pic=$( echo "$pic" | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
        php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
    fi
}

# $1 : path to pictures directory
# $2 : ...
# $3 : second image
function getDwall () {
    if (( $cl == 1 )) ; then
        echo "$1"
        exit
    fi
    if ! [[ -f "$1/.wcount" ]] ; then
         echo "0" >| "$1/.wcount"
    fi
	if ! [[ -f "$1/.picslist" ]] ; then
		subdirs=$( find "$1" -type d )
		PICSLIST=""
		while read -r ll ; do
			PICSLIST+=$(echo "" ;
                        find "$ll/"  -maxdepth 1 -type f -printf "%p\n" ;
                        echo ""
            )
		done <<< "$subdirs"
		printf '%s\n' "$PICSLIST" \
        | sort \
        | grep -v -E ".wcount$" \
        | grep -v -E "picslist$" >| "$1/.picslist"
        sed  -i '/^$/d' "$1/.picslist"
	fi
	L=$(cat "$1/.picslist"|wc -l)
    n=$(cat "$1/.wcount")
    if [[ -z "$n" ]] ; then n=1 ; fi
    case "$2" in
        -) n=$((n-1)) ;;
        +) n=$((n+1)) ;;
        *)
            number='^[0-9]+$'
            if [[ "$2" =~ $number ]]
                then
                    n="$2"
                else
                    n=$((n+1))
            fi
    esac
	if (( $n > $L )) ; then
		rm "$1/.picslist"
		n=1
    fi
	if (( $n <=0 )) ; then n="$L" ; fi
    pic=$(cat "$1/.picslist" 2>/dev/null |sed -n "$n"p )
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        if [[ -z "$3" ]]
            then feh --bg-max "$pic"
            else feh --bg-max "$pic" "$3"
        fi
    fi
    echo "$n/$L"
    echo "$n/$L" >| ~/.i3/wallpaper/wlog
	echo "$n" >| "$1/.wcount"
}

function getPauseW(){
    id=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_pause_id_$notexpired" )
    if [[ -z "$id" ]] ; then
        >&2 echo "pause wallpaper id undefined "
        exit
    fi
    number='^[0-9]+$'
    if [[ "$id" =~ $number ]]
        then pic=$(php -f "$wallhavenPhp" f=get "$id" )
        else pic="$id"
    fi
    if (( $cl == 1 )) ; then
        echo "pause : $pic"
        exit
    fi
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "${HOME}/.i3/wallpaper/w8.jpg"
    fi
    exit
}

function getFav(){
    pause=$(
        php -f "$wallhavenPhp" f=wh_get "ws${workspace}pauseValue_$notexpired"
    )
    if [[ -z "$pause" ]] ; then
        >&2 echo "pause not enabled (first use?)"
        exit
    fi
    if (( $pause == 1 )) ; then
        getPauseW
    fi
    fid=$( GETFID )
    if [[ -z "$fid" ]] ; then
        >&2 echo "wallpaper fav list id not given (first use?)"
        exit
    fi
    if (( $cl == 1 )) ; then
        php -f "$wallhavenPhp" f=getfavname "$fid"
        exit
    fi
    N=$( php -f  "$wallhavenPhp" f=getfcount "$fid" )
    id=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_lastindex_$fid" )
    id=$((id+goto))
    case "$1" in
        ""|+) id=$((id+1)) ;;
         -) id=$((id-1)) ;;
         *)
             number='^[0-9]+$'
             if [[ "$1" =~ $number ]]
                then id=$1
             fi
    esac
    [[ -z "$id" ]] && id=1
    if (( $id > $N )) ; then id=1 ; fi
    if (( $id <=0 )) ; then id=$N ; fi
    id=$((id+0))
    pic="$(php -f "$wallhavenPhp" f=getfav $fid $id )"
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}_lastindex_$fid"  "$id"
    echo "$id/$N"
    echo "$id/$N" >| ~/.i3/wallpaper/wlog
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "${HOME}/.i3/wallpaper/w8.jpg"
        else
            echo "$pic" >> "${HOME}/.i3/wallpaper/errlog"
            pic=$( echo "$pic" | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
            php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
    fi
}

function set_web_id (){
    name="web_wallhaven_${notexpired}_id"
    if [[ -z "$1" ]]
        then
            squery=$( php -f "$wallhavenPhp" f=getwebids \
                |rofi -dmenu -p "set $name" -width -60
            )
            if [[ -z "$squery" ]] ; then
                >&2 echo "squery unchanged"
                exit
            fi
            squery=${squery%%(*}
        else
            squery="$1"
    fi
    php -f "$wallhavenPhp" f=wh_set "$name" "$squery"
}

function get_web_id (){
    name="web_wallhaven_${notexpired}_id"
    php -f "$wallhavenPhp" f=wh_get "$name"
}

function set_ordered_c(){
    name="ws${workspace}_ordered_wallhaven_${notexpired}_c"
    ans=$(
        printf "d\nm\ns\ndm\nds\nsm\n" \
        | sort \
        |rofi -dmenu -p "set $name" -width -60
    )
    echo "$ans"
    php -f "$wallhavenPhp" f=wh_set "$name" "$ans"
}

function get_ordered_c(){
    name="ws${workspace}_ordered_wallhaven_${notexpired}_c"
    c=$( php -f "$wallhavenPhp" f=wh_get "$name" )
    if [[ -z "$c" ]]
        then echo "$(set_ordered_c)"
        else echo "$c"
    fi
}

# from dir (pause)
# $1 control passed through
function wsGetW(){
    dir="$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}FID_dir_$notexpired" )"
    if ! [[ -d "$dir" ]] || [[ -z "$dir" ]] ; then
        >&2 echo "wallpaper dir not defined or invalid (first use?)"
        exit
    fi
    pause=$(
        php -f "$wallhavenPhp" f=wh_get "ws${workspace}pauseValue_$notexpired"
    )
    if [[ -z "$pause" ]] ; then
        >&2 echo "pause value not defind (first use?)"
        exit
    fi
    if [[ "$2" == p ]] && (( $pause == 1 )) ; then
        getPauseW
    fi
    getDwall "$dir" "$1"
}

function wsGetWP(){
    wsGetW "$1" p
}

# random : web or offline
function wsGetwWR(){
    if (( $cl == 1 )) ; then
        echo "web wallhaven"
        exit
    fi
    code=$(ping -c 1 8.8.8.8 2>&1 |grep unreachable >/dev/null; echo $? )
    if (( code == 0 ))
          then
              pic=$(php -f "$wallhavenPhp" f=getrandom d )
          else
              squery="$(get_web_id)"
              if (( $notexpired == 1 )) ;
                    then c='s'
                    else c='d'
              fi
              pic=$( "$wallhavenScript" "$c" "$squery" )
    fi
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max  "$pic" "${HOME}/.i3/wallpaper/w8.jpg"
        else
            pic=$( echo "$pic" | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
            php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
    fi
    pic=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
    echo $pic
    exit
}

function uncategorised(){
    pic="$(php -f "$wallhavenPhp" f=uncategorised | head -1 )"
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "${HOME}/.i3/wallpaper/w8.jpg"
    fi
}

function printOrd(){
    pic=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
    number='^[0-9]+$'
    if [[ -z "$pic" ]] || ! [[ "$pic" =~ $number ]] ; then
        >&2 echo "not a wallhaven list?"
        dunstify -u normal -r "$msgId"  "wallpaper changer" "not a wallhaven list"
        exit
    fi
    c=$(get_ordered_c)
    name="ws${workspace}_lastindex_$c"
    id=$(php -f "$wallhavenPhp" f=wh_get "$name" )
    php -f "$wallhavenPhp" f=getordered $id $c 50 > /tmp/chwlp_feh_dir_list
    feh --index-info "%u\n" \
        -x -m -W 1920 -H 1080 \
        -E 180 -y 180  \
        -f /tmp/chwlp_feh_dir_list 2> /dev/null
    exit
}

function printDir(){
    dir="$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}FID_dir_$notexpired" )"
    if ! [[ -d "$dir" ]] || [[ -z "$dir" ]] ; then
        >&2 echo "wallpaper dir not defined or invalid (first use?)"
        exit
    fi
    n=$(cat "$dir/.wcount")
    sed -n "$n,+50"p "$dir/.picslist" > /tmp/chwlp_feh_dir_list
    feh --index-info "%u\n" \
        -x -m -W 1920 -H 1080 \
        -E 180 -y 180  \
        -f /tmp/chwlp_feh_dir_list
    exit
}

function listthem(){
    mode=$(wsgetMode)
    case "$mode" in
                getFav) printFav ;;
        wsGetW|wsGetWP) printDir ;;
            getOrdered) printOrd ;;
    esac
    dunstify -u normal -r "$msgId"  "wallpaper changer" "not a printable list"
}

function wlist_f (){
    if [[ -z  "$1" ]]
        then c=d
        else c=$1
    fi
    php -f "$wallhavenPhp" f=getfavlist "$c"
    exit
}

function setPauseValue(){
    ! [[ -z "$1" ]] && [[ "$1" != "f" ]] && workspace=$1
    pause=$(
        php -f "$wallhavenPhp" f=wh_get "ws${workspace}pauseValue_$notexpired"
    )
    if (( $pause == 0 ))
    then
        pause=1
        msg="DISABLED"
    else
        pause=0
        msg="ENABLED"
    fi
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}pauseValue_$notexpired"  "$pause"
    message="wallpaper changing is <b>$msg</b> for workspace $workspace"
    echo "$msg"
    dunstify -u normal -r "$msgId" "wallpaper changer" "$message"
}

function downloadit(){
    imgID="$1"
    c="$2"
    pic=$( "$wallhavenScript" g $imgID $c )
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max  "$pic" "${HOME}/.i3/wallpaper/w8.jpg"
    fi
    exit
}

function modes_f(){
    echo "exit : disable"
    echo "getFav :get wallpapers from favs list [0,1,pause]"
    echo "wsGetW :local dir (not wallhaven) [0,1]"
    echo "wsGetWP :local dir (not wallhaven) [0,1,pause]"
    echo "wsGetwWR :random web or offline [0,1]"
    echo "getPauseW :a single unchanging wallpaper [0,1]"
    echo "getOrdered :all available wallpapers (sorted by category) [0,1]"
}

function wsSetMode(){
    ! [[ -z "$1" ]] && workspace=$1

    ans=$(
        modes_f |rofi -dmenu -p "workspaces $workspace mode" -width -70
    )
    if [[ -z "$ans" ]] ; then
        >&2 echo "empty choice"
        exit
    fi
    if  (( $notexpired == 0 )) && (( $workspace <= 7 ))
    then
        if [[ "$(pass_f)" == "0" ]] ; then
            dunstify -u normal -r "$msgId" "wallpaper changer" "not permitted"
            echo
            exit
        fi
    fi
    name="ws${workspace}_mode_$notexpired"
    php -f "$wallhavenPhp" f=wh_set "$name"  "${ans% :*}"
    echo "mode ($notexpired) : ${ans% :*}"
}

function wsgetMode(){
    name="ws${workspace}_mode_$notexpired"
    mode=$(php -f "$wallhavenPhp" f=wh_get "$name" )
    if [[ -z "$mode" ]] ; then
        echo "mode not defined yet"
        dunstify -u normal -r "$msgId" "wallpaper changer" "mode not defined yet"
        exit
    fi
    if [[ $1 == x ]]
        then $mode "$2"
        else echo "$mode" ; exit
    fi
}

case "$1" in
     af|addfav)     addFav "$2"  ;;
    al|addlist)     addFAVLIST "$2" "$3" ;;
             c)     echo "$( _pic_ )" ; exit ;;
            cl)     cl=1 ;;
            cm)     echo "$(wsgetMode)($notexpired)" ;;
    d|download)     downloadit "$2" "$3" ;;
           dim)
                    pic=$( _pic_ )
                    dim=$( identify -format '%w  %h' "$pic"  )
                    dim=( $dim )
                    echo "${dim[0]}x${dim[1]}"
                    exit
                    ;;
           dir)     dirHandler ;;
      fav[sdm])     changeFavList "${1#fav}" "$2" ;;
           fix)     fix_m ;;
             g)     goto="$2"; goto=$((goto-1)) ;;
        h|help)     f_help ;;
          i|id)
                    pic=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
                    echo $pic
                    exit ;;
        l|list)     listthem "$2" ;;
            lm)     modes_f ; exit ;;
             o)     feh "$( _pic_ )" & disown ; exit ;;
            ow)
                    pic=$( _pic_ | sed -E 's@^.*wallhaven-([0-9]*).*$@\1@g' )
                    number='^[0-9]+$'
                    if ! [[ "$id" =~ $number ]] ; then
                        echo not a wallhaven wallpaper
                        exit
                    fi
                    firefox "https://alpha.wallhaven.cc/wallpaper/$pic" & disown
                    ;;
        p|pause)    setPauseValue "$2"  ;;
           r|rm)    rmFav ;;
             sc)    set_ordered_c ;;
    sp|setpause)    setPauseW "$2" "$3" ;;
     sm|setmode)    wsSetMode "$2" "$3" ;;
     u|unexpire)    unexpire ;;
            url)    "$wallhavenScript" url ; exit ;;
          wlist)    wlist_f "$2" ;;
            wid)    set_web_id "$2" ;;
           zoom)
                    pic=$( _pic_ )
                    feh --bg-scale   "$pic" "${HOME}/.i3/wallpaper/w8.jpg"
                    exit
                    ;;
esac

wsgetMode x "$1"
sleep 1.2

