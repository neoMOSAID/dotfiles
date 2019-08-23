#!/bin/bash
phpPplay="${HOME}/OneDrive/OneDrive/www/phpTests/pplay/pplay.php"
phpfr1="${HOME}/OneDrive/OneDrive/www/phpTests/fr1/fr1.php"
mpvsocketfile=/tmp/pplay_mpvsocket
pidfile=/tmp/pplay_pid
datafile=/tmp/pplay_data
playlistFile=/tmp/pplay_mpv_playlistFile

function _printhelp () {
    printf '\t%-15s\t%s\n' "$1" "$2"
}

function f_help(){
    printf '\033[01;36m\n'
    echo "  highly customized and user friendly playlists with mpv player"
    printf " \t \t powred by php/Mysql Database\n"
    printf '\033[01;00m\n'
    _printhelp "h,help" "print this help"
    _printhelp "" "play next"
    _printhelp "  [number]" "play nth item of the list"
    _printhelp "p [number]" "play nth item of the list --loop"
    _printhelp "o [number]" "play file by database ID"
    _printhelp "rand,sorted" "play random,sorted playlist"
    _printhelp "l,list" "print playlist"
    _printhelp "k,kill" "kill mpv"
    _printhelp "pid" "print mpv process id"
    _printhelp "id" "print current file database id"
    _printhelp "info" "tail info file"
    _printhelp "a,add [link]" "add to list"
    _printhelp "i,index" "show index of current video"
    _printhelp "t,title" "show title of currently played item"
    _printhelp "   [pattern]" "play videos with [pattern] in filename/title"
    _printhelp "ss [pattern]" "search videos with [pattern] in filename/title"
    _printhelp "sl [pattern]" "play videos with [pattern] in filename/title"
    _printhelp "s  [pattern]" "search pattern(s) in current list"
    _printhelp "u,url" "current file/url"
    _printhelp "r,remove" "remove current song from playlist"
    _printhelp "move" "change current song's playlist"
    _printhelp "m,mode" "show playlist id"
    _printhelp "n,playlistName" "show playlist name"
    _printhelp "m [number]" "change playlist"
    _printhelp "playlists" "change playlist"
    _printhelp "addlist" "add playlist to database"
    _printhelp "status" "print stats"
}

#
function f_play(){
    pplay_pid=$( f_pid )
    mode=$( f_mode )
    case "$1" in
        "" )
            if [[ -z "$pplay_pid" ]] ; then
                if (( $mode == 9 )) ; then
                    [[ -t 1 ]] || exit
                    read -s -p " > " pass
                    echo
                    result=$( php  -f  "$phpfr1" f=authenticate chwlpf "$pass" )
                    [[ "$result" == 1 ]] || exit
                fi
                m_play "sorted" "" ""
                return
            fi
            index=$( f_index  )
            index=$((index+1))
            f_goto "$index"
            ;;
        rand|sorted) m_play "$1" "" "" ;;
         * )
             number='^[0-9]+$'
             if [[ "$1" =~ $number ]]
                then
                    if [[ -z "$pplay_pid" ]] ; then
                        if (( $mode == 9 )) ; then
                            read -s -p " > " pass
                            echo
                            result=$( php  -f  "$phpfr1" f=authenticate chwlpf "$pass" )
                            [[ "$result" == 1 ]] || exit
                        fi
                        m_play "sorted" "$1" "$2"
                        return
                    fi
                    index=$1
                    f_goto "$index"
                else
                    f_load "$@"
                    return
             fi
    esac
}

function f_goto(){
    number='^[0-9]+$'
    if [[ "$1" =~ $number ]] ; then
        index="$1"
        [[ "$index" != "0" ]] && index=$((index-1))
        cmd='{ "command": ["set_property", "playlist-pos", "'
        cmd+="$index"
        cmd+='" ] }'
        echo "$cmd" | socat - "$mpvsocketfile" >/dev/null
    fi
}

function f_showText(){
    cmd='{ "command": ["get_property", "playlist-count"] }'
    N=$( echo "$cmd" \
        | socat - "$mpvsocketfile" \
        | sed 's/[{}"]//g;s/,error:success//;s/data://' )
    cmd='{ "command": ["get_property", "playlist-pos"] }'
    n=$( echo "$cmd" \
        | socat - "$mpvsocketfile" \
        | sed 's/[{}"]//g;s/,error:success//;s/data://' )
    n=$((n+1))
    text="$n/$N"
    cmd='{ "command": [ "show-text", "'$text'" ] }'
    echo "$cmd" | socat - "$mpvsocketfile" >/dev/null 2>&1
    echo "$text"
}

# $1 order= sorted, rand
# $2 index
# $3 loop
function m_play() {
    order="$1"
    index="$2"
    loop="$3"
    mode=$(f_mode)
    php -f "$phpPplay" f=getplaylist "id=$mode" "order=$order" \
    | jq '.files[]'|sed 's/"//g' > "$playlistFile"
    if [[ -z "$index" ]] ; then
        index=$( php -f "$phpPplay" f=getindex list=$mode )
    fi
    index=$((index-1))
    [[ -f "$pidfile" ]] && {
        kill -9 $(cat "$pidfile" ) 2>/dev/null
    }
    mpv --input-ipc-server=$mpvsocketfile \
        --quiet \
        --playlist="$playlistFile" --playlist-start=$index $loop \
        --volume=30 > "$datafile" 2>&1  & disown
    pid="$!"
    echo "$pid" >| "$pidfile"
}

function f_title () {
    cmd='{ "command": ["get_property", "media-title"] }'
    title=$( echo "$cmd" \
        | socat - "$mpvsocketfile" 2>/dev/null \
        | sed 's/[{}"]//g;s/,error:success//;s/data://' )
    if (( ${#title} <= 1 )) ; then
        title=$(youtube-dl -j "$(f_url)" 2>/dev/null \
            |jq -r ".alt_title"
        )
    fi
    #pplay_pid=$( f_pid )
    #title=$( wmctrl -lp \
    #        | sed -n "/$pplay_pid/p" \
    #        | awk '{for(i=5;i<NF-1;i++)  printf("%s ",$i) }'\
    #        | sed 's/[ ]*$//g'
    #)
    echo "$title"
}

function f_index(){
    pplay_pid=$( f_pid )
    if [[ -z "$pplay_pid" ]] ; then
        echo 0
        return
    fi
    url=$(f_url)
    index=$(cat "$playlistFile" \
            | grep -Fn "$url" 2>/dev/null \
            | head -1 |cut -f1 -d:
    )
    echo $index
}


function f_playlistName(){
    mode=$( f_mode )
    php -f "$phpPplay" f=getlistname "id=$mode"
}

function f_url(){
    cat "$datafile" \
    |sed -n '/cplayer: Playing:/p' \
    |tail -1 \
    |sed 's/cplayer: Playing: //g' \
    |sed -r 's/^\s+//g'
}

function f_isUrl(){
    url=$(f_url )
    if echo "$url"| grep -F 'www.youtube.com/watch?v=' >/dev/null
        then echo 1
        else echo 0
    fi
}

function f_saveIndex(){
    mode=$(f_mode)
    index=$( f_id )
    >&2 echo "saving index $mode : $index"
    php -f "$phpPplay" f=setindex "list=$mode" "index=$index"
}

function f_list(){
    mode=$(f_mode)
    pplay_pid=$(f_pid)
    if [[ -z "$pplay_pid" ]] ; then
        if (( $mode == 9 )) ; then
            read -s -p " > " pass
            echo
            result=$( php  -f  "$phpfr1" f=authenticate chwlpf "$pass" )
            [[ "$result" == 1 ]] || exit
        fi
    fi
    index=$(f_index)
    data=$( php -f "$phpPplay" f=gettitles "list=$mode" "index=$index" )
    nb=$(echo "$data" | jq length )
    echo "$data" \
    |jq -r '.[]| "\(.index)|\(.title)"' \
    | awk -F'|' -v v="$index" ' {
        x=$1;
        $1="";
        if (NR == v ) printf("\033[1;31m%5d|%s\n",x,$0);
        else printf("\033[1;32m%5d|\033[1;0m%s\n",x,$0);
        }' \
    | less +"$index"
}

function f_kill(){
    [[ -f "$pidfile" ]] && {
        kill -9 $(cat "$pidfile" ) 2>/dev/null
    }
}

function f_playlists(){
    echo
    m=$( f_mode )
    while read -r l ; do
        listname=$( echo "$l" | cut -d: -f2 )
        listID=$(echo "$l" | cut -d: -f1 )
        if [[ "$1"  == "q" ]]
        then
            printf '\t%2d: %-20s\n' "$listID" "$listname"
        else
            n=$(php -f "$phpPplay" f=getnfiles "list=$listID" )
            if (( $listID == $m ))
            then
                printf '\033[1;31m\t%2d: %-20s:\033[1;32m%5s\033[1;0m files\n' "$listID" "$listname" "$n"
            else
                printf '\033[1;0m\t%2d: %-20s:\033[1;32m%5s\033[1;0m files\n' "$listID" "$listname" "$n"
            fi
        fi
        ii=$((ii+1))
    done <<< "$(php -f "$phpPplay" f=getlists)"
    if [[ "$1"  != "q" ]] ; then
        echo
        read -r -p " load playlist number : " answer order
        number='^[0-9]+$'
        if [[ "$answer" =~ $number ]] ; then
            f_chmode "$answer" p $order
        fi
    fi
}

function f_saveTitle(){
    mode=$( f_mode )
    title=$( f_title )
    url=$( f_url )
    >&2 echo "saving title $title"
    php -f "$phpPplay" f=addtitle "list=$mode" "file=$url" "title=$title"
}

function f_addToList(){
    f_playlists q
    [[ -z "$1" ]] && url="$(f_url)" || url="$1"
    url="${url//\\/}"
    echo
    printf '  \033[1;36murl:\033[1;32m%s\033[1;0m\n' "$url"
    echo
    read -r -p "  add it to playlist: " answer
    number='^[0-9]+$'
    if [[ "$answer" =~ $number ]] ; then
        #php -f "$phpPplay" f=setmode "mode=$answer"
        result=$( php -f "$phpPplay" f=addfile "list=$answer" "file=$url" )
        if echo "$result" | grep -i duplicate >/dev/null
            then echo "  file exists"
            else echo "  file added"
        fi
        #index=$(php -f "$phpPplay" f=getnfiles "$answer" )
        #f_kill
        #f_play "$index"
    fi
}

function f_mode(){
    php -f "$phpPplay" f=getmode
}

function f_chmode(){
    case "$1" in
       "" ) f_mode ;;
        l ) f_playlists q ;;
        * )
            number='^[0-9]+$'
            if [[ "$1" =~ $number ]] ; then
                if (( $1 == 9 )) ; then
                    read -s -p " > " pass
                    echo
                    result=$( php  -f  "$phpfr1" f=authenticate chwlpf "$pass" )
                    [[ "$result" == 1 ]] || exit
                fi
                f_kill
                php -f "$phpPplay" f=setmode "mode=$1"
                if [[ "$2" == p ]] ; then f_play "$3" ; fi
            fi
    esac
}

function f_pid(){
    ! [[ -f "$pidfile" ]] && return
    pid=$(cat "$pidfile")
    if pgrep mpv | grep -w $pid >/dev/null
        then echo $pid
    fi
}

function f_info(){
    tail -f "$datafile"
}

function f_search(){
    ii=0
    for i do
        if (($ii!=0)) ; then
            query+=" \"$i\" "
            gquery+="$i|"
        fi
        ii=$((ii+1))
    done
    gquery="${gquery::-1}"
    php -f "$phpPplay" f=search "query=$query" \
    | awk -F: '{
                 a=$1;
                 $1="";
                 printf("%5d: %s\n",a,$0);
             }' \
    | grep  --color=always -iE "$gquery"
}

function f_load(){
    f_search "$@" | while read -r l ; do
                        id=$(echo "$l" | cut -d: -f1)
                        php -f "$phpPplay" f=getfile "id=$id"
                        echo
                    done > "$playlistFile"
    [[ -f "$pidfile" ]] && {
        kill -9 $(cat "$pidfile" ) 2>/dev/null
    }
    mpv --input-ipc-server=$mpvsocketfile \
        --quiet \
        --playlist="$playlistFile" \
        --volume=30 > "$datafile" 2>&1  & disown
    pid="$!"
    echo "$pid" >| "$pidfile"
}

function f_remove(){
    mode="$( f_mode )"
    file="$( f_url )"
    echo
    f_index
    echo "$file"
    f_title
    echo
    printf '\033[1;31m'
    read -r -p " remove it (y/N) ? : " answer
    printf '\033[1;0m'
    [[ "$answer" == "y" ]] || return
    php -f "$phpPplay" f=removefile "list=$mode" "file=$file"
    f_kill
    f_play
}

function f_open(){
    number='^[0-9]+$'
    if [[ "$1" =~ $number ]] ; then
        listID=$( php -f "$phpPplay" f=getlistbyid id=$1 )
        f_chmode "$listID"
        index=$( php -f "$phpPplay" f=getindexbyid "list=$listID" "id=$1" )
        echo $index
        f_play "$index" "--loop"
    fi
}

function f_lsearch(){
    echo ""
}

function f_find(){
    ii=0
    for i do
        if (($ii!=0)) ; then
            query+="$i|"
        fi
        ii=$((ii+1))
    done
    query="${query::-1}"
    f_list | grep --color=always -iE "$query"
}

function f_stats(){
    pplay_pid=$( f_pid )
    if [[ -z "$pplay_pid" ]] ; then
        echo not playing anything
        return
    fi
}
function f_id(){
    list="$(f_mode)"
    file="$(f_url)"
    php -f "$phpPplay" f=getfileid "list=$list" "file=$file"
}

function f_addlist(){
    php -f "$phpPplay" f=addlist "listname=$1"
}

function f_move(){
    id=$(f_id)
    list=$(f_mode)
    f_playlists q
    echo
    printf '  \033[1;36mid:\033[1;32m%s\033[1;0m\n' "$id"
    echo
    read -r -p "  move it to playlist: " tolist
    number='^[0-9]+$'
    if [[ "$tolist" =~ $number ]] ; then
        php -f "$phpPplay" f=movefile "list=$list" "id=$id" "tolist=$tolist"
        echo "  moved."
    fi
}

function f_Nfiles(){
    cmd='{ "command": ["get_property", "playlist-count"] }'
    N=$( echo "$cmd" \
        | socat - "$mpvsocketfile" \
        | sed 's/[{}"]//g;s/,error:success//;s/data://' )
    echo $N
}

function f_playNext(){
    echo 'playlist-next' | socat - "$mpvsocketfile"
    f_showText
}

function f_playPrev(){
    echo 'playlist-prev' | socat - "$mpvsocketfile"
    f_showText
}

function f_changeList(){
    php -f "$phpPplay" f=changelist "id=$1" "list=$2"
}

case "$1" in
            i|index) f_index ;;
            t|title) f_title ;;
             h|help) f_help ;;
             m|mode) f_chmode "$2" "$3" "$4" ;;
             k|kill) f_kill ;;
             l|list) f_list ;;
                 id) f_id ;;
                pid) f_pid ;;
               info) f_info ;;
             status) f_stats ;;
             p|play) f_goto "$2" ;;
              u|url) f_url ;;
          playlists) f_playlists ;;
     n|playlistName) f_playlistName ;;
              a|add) f_addToList "$2" ;;
           r|remove) f_remove  ;;
               move) f_move  ;;
          saveTitle) f_saveTitle ;;
          saveIndex) f_saveIndex ;;
            addlist) f_addlist "$2"  ;;
      cl|changelist) f_changeList "$2" "$3" ;;
          ss|search) f_search "$@"  ;;
             s|find) f_find "$@" ;;
            sl|load) f_load "$@"  ;;
             o|open) f_open "$2" ;;
                  N) f_Nfiles ;;
                  +) f_playNext ;;
                  -) f_playPrev ;;
                  *) f_play "$@" ;;
esac

