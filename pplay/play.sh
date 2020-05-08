#!/bin/bash
PyScript="${HOME}/.i3/pplay/pplayDB.py"
mpvsocketfile=/tmp/pplay_mpvsocket
pidfile=/tmp/pplay_pid
modeFile=/tmp/pplay_mode
datafile=/tmp/pplay_data
playlistFile=/tmp/pplay_mpv_playlistFile

function f_pid(){
    ! [[ -f "$pidfile" ]] && return
    pid=$(cat "$pidfile")
    if pgrep mpv | grep -w "$pid" >/dev/null
    then echo $pid
    fi
}

pplay_pid=$( f_pid )

[[ "$1" == pid ]] && {
    echo "$pplay_pid"
    exit
}

if [[ -z "$pplay_pid" ]]
    then
        rm "$mpvsocketfile" 2>/dev/null
        rm "$pidfile"  2>/dev/null
        rm "$modeFile"  2>/dev/null
        rm "$datafile"  2>/dev/null
        rm "$playlistFile"  2>/dev/null
        mode=$( python "$PyScript" get current )
        [[ -z "$mode" ]]  && {
            >&2 echo "error mode not set"
            if [[ "$1" != playlists ]]
                then    exit
                else    mode=0
            fi
        }
        if (( $mode == 9  || $mode == 8 )) && [[ "$1" != playlists ]] ; then
            [[ -t 1 ]] || exit
            read -s -p " > " pass
            echo
            result=$( python "$PyScript" authenticate pplay "$pass" 1 )
            [[ "$result" == 0 ]] && {
                exit
            }
        fi
        echo "$mode" >| "$modeFile"
    else
        mode=$(cat "$modeFile" )
fi

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
    case "$1" in
        "" )
            index=$( f_index  )
            if [[ -z "$pplay_pid" ]]
                then
                    [[ -z $index ]] && index=1
                    m_play "sorted" "$((index-1))" ""
                else
                    index=$((index+1))
                    f_goto "$index"
            fi
            ;;
        rand|sorted|removed) m_play "$1" "" "" ;;
        * )
            number='^[0-9]+$'
            if [[ "$1" =~ $number ]]
            then
                index=$1
                if [[ -z "$pplay_pid" ]]
                    then
                        m_play "sorted" "$index" "$2"
                    else
                        f_goto "$index"
                fi
            else
                f_load "$@"
                return
            fi
    esac
}

function f_goto(){
    cmd='{ "command": ["get_property", "playlist-count"] }'
    N=$( echo "$cmd" \
        | socat - "$mpvsocketfile" \
        | jq '.data'
    )
    number='^[0-9]+$'
    if [[ "$1" =~ $number ]] ; then
        index="$1"
        [[ "$index" != "0" ]] && index=$((index-1))
        (( $index >= $N )) && index=0
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
        | jq '.data'
    )
    cmd='{ "command": ["get_property", "playlist-pos"] }'
    n=$( echo "$cmd" \
        | socat - "$mpvsocketfile" \
        | jq '.data'
    )
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
    removed=0
    if [[ "$order" == removed ]]
        then
            removed=1
            index=0
    fi
    rm "$playlistFile" 2>/dev/null
    python "$PyScript" getfiles "$mode" "$removed" >| "$playlistFile"
    if [[ -z "$index" ]] ; then
        index=$( python "$PyScript" get "index_$mode" )
    fi
    [[ -z "$index" ]] && index=1
    [[ -f "$pidfile" ]] && {
        kill -9 $(cat "$pidfile" ) 2>/dev/null
    }
    mpv --input-ipc-server=$mpvsocketfile \
    --quiet --loop-file=no \
    --playlist="$playlistFile" --playlist-start=$index $loop \
    --volume=30 > "$datafile" 2>&1  & disown
    pid="$!"
    echo "$pid" >| "$pidfile"
}

function f_time () {
    cmd='{ "command": ["get_property", "time-pos"] }'
    t=$( echo "$cmd" \
        | socat - "$mpvsocketfile" 2>/dev/null \
        | jq '.data' \
    )
    echo "$(date --date "@$t"  '+%H:%M:%S' 2>/dev/null )"|
    sed 's/00://'
}

function f_totaltime () {
    cmd='{ "command": ["get_property", "duration"] }'
    t=$( echo "$cmd" \
        | socat - "$mpvsocketfile" 2>/dev/null \
        | jq '.data' \
    )
    echo "$(date --date "@$t"  '+%H:%M:%S' 2> /dev/null )" |
        sed 's/00://'
    }

function f_title () {
    cmd='{ "command": ["get_property", "media-title"] }'
    title=$( echo "$cmd" \
        | socat - "$mpvsocketfile" 2>/dev/null \
        | jq '.data' \
        | sed 's/"//g'
    )
    if (( ${#title} <= 1 )) ; then
        title=$(youtube-dl -j "$(f_url)" 2>/dev/null \
            |jq -r ".alt_title"
        )
    fi
    #title=$( wmctrl -lp \
    #        | sed -n "/$pplay_pid/p" \
    #        | awk '{for(i=5;i<NF-1;i++)  printf("%s ",$i) }'\
    #        | sed 's/[ ]*$//g'
    #)
    echo "$title"
}

function file_by_index(){
    if [[ -z "$pplay_pid" ]] ; then
        echo 0
        return
    fi
    url=$(sed -n "$1"p "$playlistFile" )
    echo $url
}

function f_index(){
    if [[ -z "$pplay_pid" ]] ; then
        python "$PyScript" get "index_$mode"
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
    python "$PyScript" getlistname "$mode"
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
    index=$( f_index )
    >&2 echo "saving index $mode : $index"
    python "$PyScript" set "index_$mode" "$index"
}

function f_list(){
    index=$(f_index)
    python "$PyScript" gettitles "$mode" |
    awk -v v="$index" ' {
        if ( $0 == "None" ) $0 = "\033[1;33m" $0 "\033[1;0m"
        if (NR == v ) printf("\033[1;31m%5d|%s\n",NR,$0);
        else printf("\033[1;32m%5d|\033[1;0m%s\n",NR,$0);
    }' |
    sed 's/,request_id:0//g' |
    less +"$index" -R
}

function f_updatedb(){
    [[ -n "$3" ]] && mode=$3
    [[ -z "$mode" ]] && {
        echo mode not set
        return
    }
    echo updating list $mode ...
    k=0
    if [[ -n "$2" ]]
    then start=$2
    else start=0
    fi
    { python "$PyScript" all "$mode"  "$1" |
    while read -r l ; do
        k=$((k+1))
        (( $k <= $start )) && continue
        title=$( youtube-dl --get-title "$l" 2>/dev/null )
        if [[ -z "$title" ]]
            then
                echo "$l"
                echo
                printf '\033[1;31m delete it ? (y/N) : '
                answer="n"
                read -u 3  answer
                [[ "$answer" == "y" ]] || continue
                python "$PyScript" delete "$l"
                echo "deleted : $l"
                printf '\033[1;0m'
            else
                echo "$k: $title"
                python "$PyScript" addtitle "$l" "$title"
        fi
    done; } 3<&0
}

function f_kill(){
    [[ -f "$pidfile" ]] && {
        kill -9 $(cat "$pidfile" ) 2>/dev/null
    }
}

function f_playlists(){
    [[ -z "$mode" ]] && mode=0
    while read -r l ; do
        listname=$( echo "$l" | cut -d: -f2 )
        listID=$(echo "$l" | cut -d: -f1 )
        if [[ "$1"  == "q" ]]
        then
            printf '\t%2d: %-20s\n' "$listID" "$listname"
        else
            n=$(python "$PyScript" getnfiles "$listID" )
            if (( $listID == $mode ))
            then
                printf '\033[1;31m\t%2d: %-20s:\033[1;32m%5s\033[1;0m files\n' "$listID" "$listname" "$n"
            else
                printf '\033[1;0m\t%2d: %-20s:\033[1;32m%5s\033[1;0m files\n' "$listID" "$listname" "$n"
            fi
        fi
        ii=$((ii+1))
    done <<< "$(python "$PyScript" getlists)"
    if [[ "$1"  != "q" ]] ; then
        echo
        read -r -p " load playlist number : " answer order
        number='^[0-9]+$'
        if [[ "$answer" =~ $number ]] ; then
            f_chmode "$answer"
        fi
    fi
}

function f_saveTitle(){
    title=$( f_title )
    url=$( f_url )
    >&2 echo "saving title $title"
    python "$PyScript" addtitle "$url" "$title"
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
        fileID=$( python "$PyScript" add  "$url" )
        result=$( python "$PyScript" addtolist "$answer" "$fileID" )
        if echo "$result" | grep -i constraint >/dev/null
            then echo "  file exists"
            else echo "  file added"
        fi
        #index=$(python "$PyScript" getnfiles "$answer" )
        #f_kill
        #f_play "$index"
    fi
}

function f_chmode(){
    mode=$1
    number='^[0-9]+$'
    if [[ "$mode" =~ $number ]] ; then
        if (( $mode == 9  || $mode == 8 )) ; then
            [[ -t 1 ]] || exit
            read -s -p " > " pass
            echo
            result=$( python "$PyScript" authenticate pplay "$pass" 1 )
            [[ "$result" == 1 ]] || exit
        fi
        f_kill
        echo "$mode" >| "$modeFile"
        python "$PyScript" set current "$mode"
        f_play
    fi
}

function f_info(){
    tail -f "$datafile"
}

function f_search(){
    ii=0
    t=" t1.title like "
    for i do
        if (($ii!=0)) ; then
            gquery+=" $t '%$i%' OR"
        fi
        ii=$((ii+1))
    done
    gquery="${gquery::-3}"
    python "$PyScript" search "$mode" "$gquery"
}

function f_load(){
    rm "$playlistFile" 2>/dev/null
    f_search "$@" > "$playlistFile"
    [[ -f "$pidfile" ]] && {
        kill -9 $(cat "$pidfile" ) 2>/dev/null
    }
    mpv --input-ipc-server=$mpvsocketfile \
    --quiet --loop-file=no \
    --playlist="$playlistFile" \
    --volume=30 > "$datafile" 2>&1  & disown
    pid="$!"
    echo "$pid" >| "$pidfile"
}

# $1 : remove/restore
# $2 : file/index
function f_remove(){
    action=$1
    arg=$2
    if [[ -z "$arg" ]]
        then
            file="$( f_url )"
            f_index
            f_title
        else
            number='^[0-9]+$'
            if [[ "$arg" =~ $number ]]
                then file="$(file_by_index $arg)"
                else file="${arg//\\/}"
            fi
    fi
    echo "$mode::$file"
    echo
    printf '\033[1;31m'
    read -r -p " $action it (y/N) ? : " answer
    printf '\033[1;0m'
    [[ "$answer" == "y" ]] || return
    python "$PyScript" remove "$action" "$file"
    f_kill
    sleep 1.2
    f_play
}

#function f_open(){
#    number='^[0-9]+$'
#    if [[ "$1" =~ $number ]] ; then
#        listID=$1
#        #listID=$( python "$PyScript" getlistbyid id=$1 )
#        f_chmode "$listID"
#        index=$( python "$PyScript" get "index_$listID" )
#        echo $index
#        f_play "$index" "--loop"
#    fi
#}

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

function f_isremoved(){
    file="$(f_url)"
    r=$( python "$PyScript" isremoved "$file" )
    case "$r" in
        0) echo "$r:not removed" ;;
        1) echo "$r:removed" ;;
        2) echo "$r:banished" ;;
    esac
}

function f_stats(){
    if [[ -z "$pplay_pid" ]] ; then
        echo not playing anything
        return
    fi
}

function f_id(){
    file="$(f_url)"
    python "$PyScript" getfile "$file"
}

function f_addlist(){
    python "$PyScript" addlist "$1" "$2"
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
        python "$PyScript" movefile "$list" "$id" "$tolist"
        echo "  moved."
    fi
}

function f_Nfiles(){
    cmd='{ "command": ["get_property", "playlist-count"] }'
    N=$( echo "$cmd" \
    | socat - "$mpvsocketfile" \
    | jq '.data'
    )
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
    python "$PyScript" changelist "id=$1" "list=$2"
}

case "$1" in
    i|index) f_index ;;
    t|title) f_title ;;
    h|help) f_help ;;
    m|mode) echo "$mode"  ;;
    #cm|chmod) f_chmode "$2" "$3" ;;
    k|kill) f_kill ;;
    l|list) f_list ;;
    id) f_id ;;
    pid) echo "$pplay_pid" ;;
    info) f_info ;;
    status) f_stats ;;
    p|play) f_goto "$2" ;;
    u|url) f_url ;;
    playlists) f_playlists ;;
    n|playlistName) f_playlistName ;;
    a|add) f_addToList "$2" ;;
    r|remove) f_remove remove "$2" ;;
    ur|restore) f_remove restore "$2" ;;
    move) f_move  ;;
    saveTitle) f_saveTitle ;;
    saveIndex) f_saveIndex ;;
    addlist) f_addlist "$2" "$3" ;;
    cl|changelist) f_changeList "$2" "$3" ;;
    ss|search) f_search "$@"  ;;
    s|find) f_find "$@" ;;
    sl|load) f_load "$@"  ;;
    o|open) f_open "$2" ;;
    update) f_updatedb "$2" "$3" "$4" ;;
    N) f_Nfiles ;;
    time) f_time ;;
    totaltime) f_totaltime ;;
    isremoved) f_isremoved ;;
    +) f_playNext ;;
    -) f_playPrev ;;
    *) f_play "$@" ;;
esac
