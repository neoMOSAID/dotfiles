#!/bin/bash

wallhavenDir="${HOME}/Pictures/wallhaven"
trash="${HOME}/Pictures/trashed"
errlog="${HOME}/.wchanger_errlog"
secondPIC="${HOME}/.i3/wallpaper/w8.jpg"

wallhavenScript="$(dirname $(realpath "$0") )/getWallhaven.sh"
wallhavenPhp="$(dirname $(realpath "$0") )/db.php"
workspace=$(cat /tmp/my_i3_ws )

notexpired=$(php -f "$wallhavenPhp" f=wh_get "expired" )
goto=0
msgId="991050"
cl=0

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
        mv "$pic" "$trash"
        pic=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
        if [[ -z "$pic" ]] ; then
            echo not a wallhaven wallpaper
            exit
        fi
        php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
    fi
    exit
}

function update_f(){
    echo scanning and adding files...
    #php -f "$wallhavenPhp" f=reset
    cd "$wallhavenDir"
    data="$( find "$PWD" -type f -iname "wallhaven*" 2>/dev/null)"
    NB=$(echo "$data" | wc -l )
    nb=0
    while read -r l ; do
        id=$( basename "$l" |sed -E 's@wallhaven-(.*)\..*$@\1@g')
        dir=$( dirname "$l" )
        dir=${dir##*/}
        php -f "$wallhavenPhp" f=add "$id" "$dir" "$l"
        nb=$((nb+1))
        percentage=$( bc -l <<< "scale=2; $nb * 100 / $NB" )
        printf '%7d/%d  : %3.2f%%\n' "$nb" "$NB"   "$percentage"
        echo -en "\e[1A"
    done <<< "$data"
    echo cleaning up...
    data=$(
        php -f "$wallhavenPhp" f=getall
    )
    while read -r l ; do
        if ! [[ -f "$l" ]] ; then
            id=$( basename "$l" |sed -E 's@wallhaven-(.*)\..*$@\1@g')
            php -f "$wallhavenPhp" f="fixcategory" "$id" x
            echo "$id does not exist. marked"
        fi
    done <<< "$data"
    echo "removing deleted from categories and favs"
    php -f "$wallhavenPhp" f="resetRemoved"
}


[[ "$1" == "x" ]] && _x_
[[ "$1" == "updatedb" ]] && update_f

cmdline=$(ps -af | grep -v grep |grep wchanger.sh|grep updatedb )
is_running=$( pgrep -fc  "$(realpath "$0" )" )
if (( $is_running >= 2 )) && [[ "$cmdline" == "" ]] ; then
    >&2 echo ${0##*/} is running $is_running proccess
    exit 0
fi

function _printhelp () {
    printf '\033[1;31m  %-23s\033[1;0m\t%s\n' "$1" "$2"
}

function f_help(){
    printf '\033[01;33m'
   echo "
   multi layred wallpaper changer for i3wm powered by a mysql database,
   each workspace can have up to 8 states,
   with two modes ( default and password protected mode)
   features include (for each workspace ):
       - a single wallpaper
       - a directory of wallpapers
       - a list of favorites wallpapers
       - wallpaper changing paused/unpaused
       - montage of the next 50 wallpapers
       - ...
    "
    _printhelp "af|addfav"                     "add current wallpaper to favs"
    _printhelp "al|addlist [id] [name] [c]"    "add list"
    _printhelp "c"                             "current wallpaper path"
    _printhelp "cl"                            "current favsList"
    _printhelp "cm"                            "current mode"
    _printhelp "chl [id] [name] [c]"           "edit list name/category"
    _printhelp "d|download [id] [c]"           "download image by wallhaven id"
    _printhelp "dim"                           "wallpaper dimensions"
    _printhelp "dir"                           "wallpapers directory"
    _printhelp "fav"                      "change favsList"
    _printhelp "fix"                           "change current wallpaper's category"
    _printhelp "g [number]"                    "jump to wallpaper"
    _printhelp "get"                           "get"
    _printhelp "h,help"                        "print this help"
    _printhelp "i|id"                          "current wallpaper's wallhaven id"
    _printhelp "info"                          "info about current workspace states"
    _printhelp "l|list"                        "a montage of the next 50 wallpapers"
    _printhelp "lm"                            "list of available modes"
    _printhelp "o"                             "open current wallpaper in feh"
    _printhelp "ow"                            "open current wallpaper in browser"
    _printhelp "p|pause"                       "enable/disable wallpaper changing"
    _printhelp "r|rm"                          "remove from favs"
    _printhelp "sc"                            "set which wallpaper category to show"
    _printhelp "sd|setdir"                     "set wallhaven directory"
    _printhelp "set"                           "set"
    _printhelp "sp|setpause"                   "set current wallpaper as pause wallpaper"
    _printhelp "sm|setmode"                    "set mode for current workspace"
    _printhelp "u|unexpire"                    "enable password mode"
    _printhelp "url"                           "wallhaven search url"
    _printhelp "updatedb"                      "update database"
    _printhelp "+,-"                           "next/prev wallpaper"
    _printhelp "wlist [sdm]"                   "print favsLists names"
    _printhelp "wid"                           "set web id"
    _printhelp "x"                             "remove current wallpaper"
    _printhelp "zoom"                          "experimental not working"
    exit
}

# no args
# print the fav list id
function GETFID(){
    if [[ -z "$notexpired" ]] ; then
        >&2 echo "expire not yet defind"
        >&2 echo "first use? run : $(basename "$0") u"
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
    arr["unset"]="0"
    LIST=$( for k in "${!arr[@]}" ; do
            fid="${arr[$k]}"
            fname="$k"
            count=$(php -f "$wallhavenPhp" f=getfcount "$fid" )
            printf '%02d : %s(%d)\n' "$fid" "$fname" "$count"
            done
    )
    ans=$(
     echo "$LIST" \
     | sort \
     |rofi -dmenu -p "$2" -width -80
    )
    ans=${ans#*: }
    ans=${ans%(*}
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

# $1 = a : open images
#    =
function printFav(){
    fid=$(GETFID)
    if [[ -z "$fid" ]] ; then
        >&2 echo "no list was chosen"
        exit
    fi
    index=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_lastindex_$fid" )
    [[ -z "$index" ]] && index=1
    php -f "$wallhavenPhp" f=getfavs "$fid" | sed 's/^[0-9]*://g' > /tmp/chwlp_feh_dir_list
    case "$1" in
        o)
            feh -f /tmp/chwlp_feh_dir_list 2> /dev/null
            return
            ;;
        a)
            m_W='1920'
            index2=$((index+120))
            ;;
        *)
            m_W='1920'
            m_H='1080'
            index2=$((index+50))
    esac
    sed -n -i "$index,$index2"p  /tmp/chwlp_feh_dir_list
    feh --index-info "%u\n" \
        -x -m -W "$m_W" -H "$m_H" \
        -E 180 -y 180  \
        -f /tmp/chwlp_feh_dir_list 2> /dev/null
    exit
}

# $1 c
function addFav(){
    pic=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
    if [[ -z "$pic" ]] ; then
        echo not a wallhaven wallpaper
        exit
    fi
    c=$(php -f "$wallhavenPhp" f=getcategorybyname "$pic" )
    [[ -z "$c" ]] && c='*'
    ! [[ -z "$1" ]] && c="$1"
    msg="add wallpaper to "
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
    pic=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
    if [[ -z "$pic" ]] ; then
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
    c=$( printf "d\nm\ns" \
        |rofi -dmenu -p "category" -width -30 )
    if [[ "$c" != d ]] && [[ "$c" != 'm' ]] && [[ $notexpired == "0" ]] ; then
        [[ "$1" != "f" ]] \
        && dunstify -u normal -r "$msgId" "wallpaper changer" "not permitted" \
        && exit
        (( $( pass_f) == 0 )) && {
            echo
            exit
        }
        echo
    fi
    fid=$( favsList "$c" "$msg" )
    if [[ -z "$fid" ]] ; then
        >&2 echo "empty choice"
        exit
    fi
    (( $fid == 0 )) && fid=""
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}FID_$notexpired" "$fid"
}

function dirHandler(){
    dir0="/run/media/mosaid/My_Data/images"
    dir1="/run/media/mosaid/My_Data/images/001 images"
    declare -A arr=()
    arr=(
    ["All Images"]="${dir1}"
    ["Post Apocalyptic Wallpapers"]="${dir0}/collectionWallpapers/Post Apocalyptic Wallpapers"
    ["Nature Wallpapers"]="${dir1}/Nature Wallpapers"
    ["Islamic Wallpapers"]="${dir0}/Islamic.Wallpapers"
    ["my spring photos"]="${dir1}/Fantasy/untitled folder"
    ["Spring Nature Wallpapers"]="${dir1}/Nature Wallpapers/Spring Nature Wallpapers"
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
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}_dir_$notexpired"  "${arr[$ans]}"

}

# $1 can be workspace
function setPauseW(){
    ! [[ -z "$1" ]] && [[ "$1" != "f" ]] && workspace=$1
    id=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
    if [[ -z "$id" ]] ; then
        echo not a wallhaven wallpaper
        exit
    fi
    if [[ -z "$notexpired" ]] ; then
        >&2 echo "u not defind"
        exit
    fi
    if  (( $notexpired == 0 )) && (( $workspace > 0 && $workspace <= 7 ))
        then
            if [[ "$(pass_f)" == "0" ]] ; then
                dunstify -u normal -r "$msgId" "wallpaper changer" "not permitted"
                exit
            fi
            echo
    fi
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}_pause_id_$notexpired"  "$id"
    exit
}

# $1 can be workspace
function UnsetPauseW(){
    ! [[ -z "$1" ]] && [[ "$1" != "f" ]] && workspace=$1
    if [[ -z "$notexpired" ]] ; then
        >&2 echo "mode 1  not defind"
        exit
    fi
    if  (( $notexpired == 0 )) && (( $workspace > 0 && $workspace <= 7 ))
    then
        if [[ "$(pass_f)" == "0" ]] ; then
            dunstify -u normal -r "$msgId" "wallpaper changer" "not permitted"
            exit
        fi
        echo
    fi
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}_pause_id_$notexpired"  ""
    exit
}

function fix_m(){
    pic=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
    if [[ -z "$pic" ]] ; then
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
    pause=$(
        php -f "$wallhavenPhp" f=wh_get "ws${workspace}pauseValue_$notexpired"
    )
    if [[ -z "$pause" ]]
        then
            >&2 echo "pause value not set"
            >&2 echo "first use ? run : $(basename $0) p"
        else
            (( $pause == 1 )) && getPauseW
    fi
    category="$(get_ordered_c)"
    if (( $cl == 1 )) ; then
        echo "all available wallpapers in the category : $category"
        exit
    fi
    name="ws${workspace}_lastindex_$category"
    index=$(php -f "$wallhavenPhp" f=wh_get "$name" )
    N=$(php -f "$wallhavenPhp" f=getorderedcount "$category" )
    index=$((index+goto))
    case "$1" in
        ""|+)
            index=$(($index+1))
            if (( $index > $N )) ; then index=1 ; fi
            ;;
        -)
            index=$(($index-1))
            if (( $index <=0 )) ; then index=$N ; fi
            ;;
        *)
            number='^[0-9]+$'
            if [[ "$1" =~ $number ]]
                then index=$1
            fi
    esac
    php -f "$wallhavenPhp" f=wh_set "$name"  "$index"
    limit=1
    ! [[ -z "$2" ]] && limit=$2
    pic="$(php -f "$wallhavenPhp" f=getordered "$index" "$category" "$limit" )"
    if [[ -z "$pic" ]] ; then
        >&2 echo "empty pic"
        exit
    fi
    echo "$index/$N"
    echo "$index/$N" >| /tmp/wchanger_wlog
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "$secondPIC"
    else
        echo "$pic" >> "$errlog"
        pic=$( echo "$pic" | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
        #php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
        >&2 echo "error file : $pic"
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
    n=$((n+goto))
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
    echo "$n/$L" >| /tmp/wchanger_wlog
	echo "$n" >| "$1/.wcount"
}

function getPauseW(){
    id=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_pause_id_$notexpired" )
    if [[ -z "$id" ]] ; then
        >&2 echo "pause wallpaper id undefined "
        >&2 echo "first use? run : $(basename $0) sp "
        exit
    fi
    pic=$(php -f "$wallhavenPhp" f=get "$id" )
    [[ -z "$pic" ]] && pic="$id"
    if (( $cl == 1 )) ; then
        echo "pause : $pic"
        exit
    fi
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "$secondPIC"
    fi
    exit
}

function getFav(){
    pause=$(
        php -f "$wallhavenPhp" f=wh_get "ws${workspace}pauseValue_$notexpired"
    )
    if [[ -z "$pause" ]]
        then
            >&2 echo "pause value not set"
            >&2 echo "first use ? run : $(basename $0) p"
        else
            (( $pause == 1 )) && getPauseW
    fi
    fid=$( GETFID )
    if [[ -z "$fid" ]] ; then
        >&2 echo "wallpaper fav list id not set"
        >&2 echo "first use? run : $(basename $0) fav"
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
    echo "$id/$N" >| /tmp/wchanger_wlog
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "$secondPIC"
        else
            echo "$pic" >> "$errlog"
            pic=$( echo "$pic" | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
            #php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
            >&2 echo "error file : $pic"
    fi
}

function set_web_id (){
    name="web_id_${workspace}_${notexpired}"
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
    echo "$name = $squery"
}

function get_web_id (){
    name="web_id_${workspace}_${notexpired}"
    php -f "$wallhavenPhp" f=wh_get "$name"
}

function set_ordered_c(){
    name="ws${workspace}_ordered_wallhaven_${notexpired}_c"
    list=$(
        printf "d\nm\ndm\n"
        if (( $notexpired == 0 )) ; then
            (( $( pass_f) == 1 )) && printf "s\nds\nsm\n"
        fi
    )
    ans=$(
        echo "$list" | sort \
        |rofi -dmenu -p "set $name" -width -60
    )
    [[ -z "$ans" ]] && exit
    echo "$ans"
    php -f "$wallhavenPhp" f=wh_set "$name" "$ans"
}

# $1 notexpired
function get_ordered_c(){
    ! [[ -z "$1" ]] && local notexpired=$1
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
    dir="$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_dir_$notexpired" )"
    if ! [[ -d "$dir" ]] || [[ -z "$dir" ]] ; then
        >&2 echo "wallpaper dir not defined or invalid"
        >&2 echo "first use? run : $(basename $0) dir "
        exit
    fi
    pause=$(
        php -f "$wallhavenPhp" f=wh_get "ws${workspace}pauseValue_$notexpired"
    )
    if [[ -z "$pause" ]]
        then
            >&2 echo "pause value not set"
            >&2 echo "first use? run : $(basename $0) p"
        else
            [[ "$2" == p ]] && (( $pause == 1 )) && getPauseW
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
    pause=$(
        php -f "$wallhavenPhp" f=wh_get "ws${workspace}pauseValue_$notexpired"
    )
    if [[ -z "$pause" ]]
        then
            >&2 echo "pause value not set"
            >&2 echo "first use? run : $(basename "$0") p"
        else
            (( $pause == 1 )) && getPauseW
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
        feh --bg-max  "$pic" "$secondPIC"
        "$wallhavenScript" "adddesc" "$squery"
        else
            pic=$( echo "$pic" | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
            [[ -z "$pic" ]] && exit
            #php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
            >&2 echo "error file : $pic"
    fi
}

function uncategorised(){
    pic="$(php -f "$wallhavenPhp" f=uncategorised | head -1 )"
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "$secondPIC"
    fi
}

function printWdir(){
    if (( $notexpired == 1 ))
        then c=sm
        else c=dm
    fi
    dir=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_wdir_$notexpired" )
    index=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_lastindex_wdir_${notexpired}_$c" )
    php -f "$wallhavenPhp" f=getdir "$dir" 1 50000 $c > /tmp/chwlp_feh_dir_list
    case "$1" in
        o)
            feh -f /tmp/chwlp_feh_dir_list 2> /dev/null
            return
            ;;
        a)
            m_W='1920'
            index2=$((index+120))
            ;;
        *)
            m_W='1920'
            m_H='1080'
            index2=$((index+50))
    esac
    sed -n -i "$index,$index2"p  /tmp/chwlp_feh_dir_list
    feh --index-info "%u\n" \
        -x -m -W "$m_W" -H "$m_H" \
        -E 180 -y 180  \
        -f /tmp/chwlp_feh_dir_list 2> /dev/null
    exit
}

function printOrd(){
    pic=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
    if [[ -z "$pic" ]] ; then
        >&2 echo "not a wallhaven list?"
        dunstify -u normal -r "$msgId"  "wallpaper changer" "not a wallhaven list"
        exit
    fi
    c=$(get_ordered_c)
    name="ws${workspace}_lastindex_$c"
    index=$(php -f "$wallhavenPhp" f=wh_get "$name" )
    php -f "$wallhavenPhp" f=getordered 1 $c 50000 > /tmp/chwlp_feh_dir_list
    case "$1" in
        o)
            feh -f /tmp/chwlp_feh_dir_list 2> /dev/null
            exit
            ;;
        a)
            m_W='1920'
            index2=$((index+120))
            ;;
        *)
            m_W='1920'
            m_H='1080'
            index2=$((index+50))
    esac
    sed -n -i "$index,$index2"p  /tmp/chwlp_feh_dir_list
    feh --index-info "%u\n" \
        -x -m -W "$m_W" -H "$m_H" \
        -E 180 -y 180  \
        -f /tmp/chwlp_feh_dir_list 2> /dev/null

    exit
}

function printDir(){
    dir="$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_dir_$notexpired" )"
    if ! [[ -d "$dir" ]] || [[ -z "$dir" ]] ; then
        >&2 echo "wallpaper dir not defined or invalid"
        >&2 echo "first use? run : $(basename "$0") dir"
        exit
    fi
    index=$(cat "$dir/.wcount")
    cat "$dir/.picslist" > /tmp/chwlp_feh_dir_list
    case "$1" in
        o)
            feh -f /tmp/chwlp_feh_dir_list 2> /dev/null
            return
            ;;
        a)
            m_W='1920'
            index2=$((index+100))
            ;;
        *)
            m_W='1920'
            m_H='1080'
            index2=$((index+50))
    esac
    sed -n -i "$index,$index2"p  /tmp/chwlp_feh_dir_list
    feh --index-info "%u\n" \
        -x -m -W "$m_W" -H "$m_H" \
        -E 180 -y 180  \
        -f /tmp/chwlp_feh_dir_list 2> /dev/null
    exit
}

function listthem(){
    mode=$(wsgetMode)
    case "$mode" in
                getFav) printFav  "$1" ;;
        wsGetW|wsGetWP) printDir  "$1" ;;
            getOrdered) printOrd  "$1" ;;
                getDir) printWdir "$1" ;;
    esac
    dunstify -u normal -r "$msgId"  "wallpaper changer" "not a printable list"
}

function wlist_f (){
    if [[ -z  "$1" ]]
        then c='*'
        else c=$1
    fi
    if (( $notexpired == 0 )) && [[ "$c" != d ]] ; then
        (( $( pass_f) == 1 )) || {
            echo
            exit
        }
        echo -en "\e[1A"
        echo
    fi
    while read -r l ; do
        id=${l%%:*}
        name=${l#*:}
        count=$(php -f "$wallhavenPhp" f=getfcount "$id" )
        category=$(php -f "$wallhavenPhp" f=getfcategory "$id" )
        printf '\033[1;0m%02d : ' "$id"
        [[ "$category" == d ]] && printf '\033[1;32m'
        [[ "$category" == m ]] && printf '\033[1;34m'
        [[ "$category" == s ]] && printf '\033[1;31m'
        printf '%s' "$category"
        printf '\033[1;0m-%s' "$name"
        printf '\033[1;33m(%d)\n' "$count"
    done <<< "$(php -f "$wallhavenPhp" f=getfavlist "$c" )"
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
    pic=$( "$wallhavenScript" g "$imgID" )
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max  "$pic" "$secondPIC"
    fi
    exit
}

function saveData(){
    php -f "$wallhavenPhp" f=wh_set "data"  "$1"
}

function getData(){
    if (( $notexpired == 0 )) ;
        then
            (( $( pass_f) == 1 )) || {
                echo
                exit
            }
        echo
    fi
    php -f "$wallhavenPhp" f=wh_get "data"
    exit
}

function wDisable(){
    echo "wallpaper changing is disabled."
}

function modes_f(){
    echo "getFav :get wallpapers from favs list [0,1,pause]"
    echo "getDir :get wallpapers by dir (wallhaven)"
    echo "wsGetW :local dir (not wallhaven) [0,1]"
    echo "wsGetWP :local dir (not wallhaven) [0,1,pause]"
    echo "wsGetwWR :random web or offline [0,1]"
    echo "getOrdered :all available wallpapers (sorted by category) [0,1]"
    echo "getPauseW :a single unchanging wallpaper [0,1]"
    echo "wDisable : disable wallpaper changer"
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
    if  (( $notexpired == 0 )) && (( $workspace > 0 && $workspace <=7 ))
    then
        if [[ "$(pass_f)" == "0" ]] ; then
            dunstify -u normal -r "$msgId" "wallpaper changer" "not permitted"
            echo
            exit
        fi
        echo
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
        then $mode "$2" "$3"
        else echo "$mode" ; exit
    fi
}

function changeListName(){
    id=$1
    name=$2
    c=$3
    php -f "$wallhavenPhp" f=changelist "$id" "$name" "$c"
}

function setDir(){
    t="select directory"
    if [[ -z  "$1" ]]
        then c=d
        else c=$1
    fi
    if (( $notexpired == 0 )) && [[ "$c" != d ]] ; then
        (( $( pass_f) == 1 )) || {
            echo
            exit
        }
        echo
    fi
    data="unset dir\n"
    data+="$( php -f "$wallhavenPhp" f=getdirs "$c" )"
    dir=$( printf "$data" | sort \
        | rofi -dmenu -p "$t" -width -60
    )
    if [[ -z "$dir" ]] ; then
        >&2 echo "empty choice"
        exit
    fi
    [[ "$dir" == "unset dir" ]] && dir=""
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}_wdir_$notexpired" "$dir"
}

function getDir(){
    pause=$(
        php -f "$wallhavenPhp" f=wh_get "ws${workspace}pauseValue_$notexpired"
    )
    if [[ -z "$pause" ]]
        then
            >&2 echo "pause value not set"
            >&2 echo "first use? run : $(basename "$0") p"
        else (( $pause == 1 )) && getPauseW
    fi
    dir=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_wdir_$notexpired" )
    if [[ -z "$dir" ]] ; then
        >&2 echo "wallpaper directory not set"
        >&2 echo "first use? run : $(basename "$0") sd"
        exit
    fi
    if (( $cl == 1 )) ; then
        echo "dir : $dir"
        exit
    fi
    if (( $notexpired == 1 ))
        then c=sm
        else c=dm
    fi
    N=$( php -f  "$wallhavenPhp" f=getdircount "$dir" "$c" )
    id=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_lastindex_wdir_${notexpired}_$c" )
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
    pic="$(php -f "$wallhavenPhp" f=getdir "$dir" "$id" 1 "$c" )"
    php -f "$wallhavenPhp" f=wh_set "ws${workspace}_lastindex_wdir_${notexpired}_$c"  "$id"
    echo "$id/$N"
    echo "$id/$N" >| /tmp/wchanger_wlog
    if `file "$pic" | grep -i -w -E "bitmap|image" >/dev/null` ; then
        feh --bg-max   "$pic" "$secondPIC"
    else
        echo "$pic" >> "$wchanger_errlog"
        pic=$( echo "$pic" | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
        #php -f "$wallhavenPhp" f=fixcategory "$pic" "x"
        >&2 echo "error file : $pic"
    fi

}

function f_keys(){
    cat ~/.i3/config | grep ^binds | grep wchanger \
    | sed 's/bindsym//g;
        s/exec --no-startup-id//g;
        s@~/.i3/wchanger.sh@@g;
        s/$mod/WIN/g;
        s/mod1/ALT/g;
        s/^[ \t]*//g;
        ' | awk '{printf("%20s\t%s\n",$1,$2)}'
    exit
}
function getFav_info(){
    local info=""
    fid=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}FID_$1" )
    str="$(php -f "$wallhavenPhp" f=getfavname "$fid" )"
    ! [[ -z "$str" ]] && info="$str"
    ! [[ -z "$info" ]] && (( $2 == 1 )) \
        && info="***************"
    printf '%-13s: %s\n' "getFav $1" "$info"
}

function wsGetW_info(){
    local info=""
    dir=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_dir_$1" )
    ! [[ -z "$dir" ]] && info="$(basename "$dir")"
    ! [[ -z "$info" ]] && (( $2 == 1 )) \
        && info="***************"
    printf '%-13s: %s\n' "wsGetW $1" "$info"
}

function wsGetwWR_info(){
    local info=""
    tag=$(php -f "$wallhavenPhp" f=wh_get "web_id_${workspace}_$1")
    tagname=$( php -f "$wallhavenPhp" f=gettagname "$tag" )
    ! [[ -z "$tagname" ]] && info="$tagname"
    ! [[ -z "$info" ]] && (( $2 == 1 )) \
        && info="***************"
    printf '%-13s: %s\n' "wsGetwWR $1" "$info"
}

function getOrdered_info(){
    local info=""
    name="ws${workspace}_ordered_wallhaven_$1_c"
    category=$( php -f "$wallhavenPhp" f=wh_get "$name" )
    ! [[ -z "$category" ]] && {
        info="category $category"
    }
    ! [[ -z "$info" ]] && (( $2 == 1 )) \
        && info="***************"
    printf '%-13s: %s\n' "getOrdered $1" "$info"
}

function getDir_info(){
    local info=""
    if (( $1 == 1 ))
        then c=sm
        else c=dm
    fi
    dir=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_wdir_$1" )
    ! [[ -z "$dir" ]] && info="$dir (category $c)"
    ! [[ -z "$info" ]] && (( $2 == 1 )) \
        && info="***************"
    printf '%-13s: %s\n' "getDir $1" "$info"
}

function getPauseW_info(){
    local info=""
    pic=$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_pause_id_$1" )
    if [[ -z "$pic" ]]
        then
            info=""
            printf '%-13s: %s\n' "getPauseW $1" "$info"
            return
        else
            if (( $2 == 1 ))
                then
                    info="***************"
                    printf '%-13s: %s\n' "getPauseW $1" "$info"
                    return
                else
                    info="$pic"
                    str=$( php -f "$wallhavenPhp" f=getfavlistbyname "$pic" \
                        | sed '{s/^.*://g}'
                    )
                    printf '%-13s: %s\n' "getPauseW $1" "$info"
                    while read -r s ; do
                        printf '\t\t - %s\n' "$s"
                    done <<< "$str"
                    return
            fi
    fi
}

function wsGetWP_info(){
    return 0
}

function wDisable_info(){
    return 0
}

function f_info(){
    hide=0
    if (( $notexpired == 0 )) ; then
        [[ "$(pass_f)" == 0 ]] && hide=1
        echo -en "\e[1A"
        echo
    fi
    mode0="$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_mode_0" )_0"
    mode1="$(php -f "$wallhavenPhp" f=wh_get "ws${workspace}_mode_1" )_1"
    if (( $notexpired == 0 ))
        then
            cmode=$mode0
            amode=$mode1
        else
            cmode=$mode1
            amode=$mode0
    fi
    while read -r l ; do
        desc="${l#*:}"
        m="${l%% *}"
        f="${m}_info"
        printf '\033[1;0m'
        [[ "${m}_0" == "$cmode" ]] && printf '\033[1;32m'
        [[ "${m}_0" == "$amode" ]] && printf '\033[1;35m'
        "$f" 0 0
        printf '\033[1;0m'
        [[ "${m}_1" == "$cmode" ]] && printf '\033[1;32m'
        [[ "${m}_1" == "$amode" ]] && printf '\033[1;35m'
        "$f" 1 $hide
    done <<< "$(modes_f)"
}
function all_info(){
    ! [[ -z "$1" ]] && {
        workspace=$1
        echo "============ ws $1 =============="
        f_info
        return
    }
    [[ "$(pass_f)" == 0 ]] && {
        exit
        echo
    }
    echo -en "\e[1A"
    echo
    notexpired=1
    for (( i=0 ;i<=25; i++ )) ; do
        echo "============ ws $i =============="
        workspace=$i
        f_info
    done
}
function print_url(){
    id=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
    echo "https://wallhaven.cc/w/$id"
}

case "$1" in
     af|addfav)     addFav "$2"  ;;
    al|addlist)     addFAVLIST "$2" "$3" ;;
             c)     echo "$( _pic_ )" ; exit ;;
            cl)     cl=1 ;;
            cm)     echo "$(wsgetMode)($notexpired)" ; exit ;;
           chl)     changeListName "$2" "$3" "$4" ;;
    d|download)     downloadit "$2" ;;
           dim)
                    pic=$( _pic_ )
                    dim=$( identify -format '%w  %h' "$pic"  )
                    dim=( $dim )
                    echo "${dim[0]}x${dim[1]}"
                    exit
                    ;;
           dir)     dirHandler ;;
           fav)     changeFavList "$2" ;;
         f|fix)     fix_m ;;
             g)     goto="$2"; goto=$((goto-1)) ;;
           get)    getData  ;;
        h|help)     f_help ;;
          i|id)
                    pic=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
                    echo $pic
                    exit ;;
          info)     f_info ; exit;;
       infoall)     all_info "$2" ; exit;;
          keys)     f_keys ;;
        l|list)     listthem "$2" ;;
            lm)     modes_f ; exit ;;
             o)     feh "$( _pic_ )" & disown ; exit ;;
            ow)
                    pic=$( _pic_ | sed -E 's@^.*wallhaven-(.*)\..*$@\1@g' )
                    if [[ -z "$pic" ]] ; then
                        echo not a wallhaven wallpaper
                        exit
                    fi
                    firefox "https://wallhaven.cc/w/$pic" & disown
                    exit
                    ;;
        p|pause)    setPauseValue "$2"  ;;
           r|rm)    rmFav ;;
             sc)    set_ordered_c ;;
      sd|setdir)    setDir "$2" ;;
            set)    saveData "$2" ;;
    sp|setpause)    setPauseW "$2" "$3" ;;
     sm|setmode)    wsSetMode "$2" "$3" ;;
  up|unsetpause)    UnsetPauseW "$2" "$3" ;;
     u|unexpire)    unexpire ;;
            url)    print_url ; exit ;;
          wlist)    wlist_f "$2" ;;
            wid)    set_web_id "$2" ;;
           zoom)
                    pic=$( _pic_ )
                    feh --bg-scale   "$pic" "$secondPIC"
                    exit
                    ;;
esac

wsgetMode x "$1"

sleep 1.2

exit

