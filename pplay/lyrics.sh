#!/bin/bash
#
# get the song being played by lsof utility "list open files"
# look for similar file names of lyrics txt file names in a local directory
# print the lyrics of the best matching lyrics file name
# another version would would be to fetch the lyrics from some website like azlyrics
# curl or wget with some string manipulation would be easy to use
#

is_running=$( pgrep -fc  "$(realpath "$0" )" )
if (( $is_running >= 2 )) ; then
    >&2 echo ${0##*/} is running.
    exit 0
fi

lastLyrics="/tmp/lastLyrics"
glllrenable=$(cat /home/mosaid/.gllrenable)
if (( "$glllrenable" == 0 )) ; then
    #echo "" >| "$lastLyrics"
    echo "$artist ** $title"
    echo "getting lyrics is disabled"
    exit
fi
DIR="${HOME}/Music/My music/Lyrics"
files=$( find "$DIR/" -type f -printf "%p\n"  )
DIR="${HOME}/Music/My music/nmcpplyrics"
files+=$( find "$DIR/" -type f -printf "%p\n"  )
extensions="wma$|mp3$|mp4$|mkv$|flv$|webm$|mpg$|avi$"
if [[ -z $2 ]]
	then
        str0=$(lsof -w  -c mpd |grep -iE $extensions|tail -1| awk -F"/" '{print $NF}'|head -1 )
        str0=${str0%mp3}
	else
        str0=$( wmctrl -l \
            |grep -v wmctrl \
            |grep -iE "$2$" \
            |awk '{$1=$2=$3=""; print $0}' \
            |sed 's/-mpv//g' \
        )
        str0=${str0%-*}
fi
if (( ${#str0} < 1 ))
	   then
	        var=$(
	          echo "$processes" |
	          awk '{for(i=1;i<=NF;i++) printf $i}' FS="-c " | 		#replace "-c " by white space
	          sed 's/^ //' | 										#remove first white space
	          sed 's/ /, /g' |										#replace all white space by ","
	          sed 's/, / and /3g'									#relpace last "," by " and "
	        )
			echo "not playing anything on : $var !"
			exit
fi
str=$(echo "$str0" | sed '
                            :a;N;$!ba;s/\n/ /g;
                            s/[^a-zA-Z0-9]/ /g;
                            s/\n//g
                        ')
#aaa=$(echo "$1"|awk 'END{print index($0,"a")}')
#if (($aaa > 0))
#	then
#		PLAYING=""
#	else
#		PLAYING="\033[01;36mplaying    : \033[01;00m"
#fi
aaa=$(echo "$1"|awk 'END{print index($0,"p")}')
if (($aaa > 0))
	then
		exit
fi
IFS=', ' read -r -a array <<< $str
patterns=$(
	for element in ${array[@]}
	do
       if (( ${#element} >= 3 )) \
            && [[ ${element} != "The" ]] \
            && [[ ${element} != "the" ]]
	   then
			echo -n "$element|"
	 fi
	done
)
patterns=${patterns::-1}
f=$(echo "$files" | awk '{ print NF,$0 }' IGNORECASE=1 FS="$patterns" | sort -nr )
f=$(echo "$f" |head -9 )
nbrOFmatches=$( echo "$f" | awk ' NR==1 { print $1 }')
if (( $nbrOFmatches <= 1)) ; then
		>&2 echo "no lyrics found."
		exit
fi
bmatch=$(echo "$f"|awk 'NR==1 {for(i=2;i<=NF;i++) printf $i" "}')
bmatch=$( basename "$bmatch" )
>&2 printf "\033[01;36mbest match : \033[01;00m$bmatch\n"
#nn=$(echo "$f"|awk 'NR==1 {a=$1} NR==2 {b=$1} END {if( a ~ b )print "1"} ')
#if [[  "$nn" == 1 ]] && [[ -t 1 ]]
# then
#   echo "========================================="
#   echo "$f"| sed -e 's@/.*/@ @g' | cat -n
#   IFS= read -rN 1 -p " : " answer
#   if [[ -z "$answer" ]] ;
#    then
#	#	exit
#	answer=1
#   fi
#  else
#      answer=1
#fi
answer=1
ff=$(echo -e "$f"|sed -n "$answer"p |awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}')
fff=$(basename "$ff" )
rr=""
#rr=$(echo "$fff"; echo)
rr+=$(cat "$ff"| sed 's/[^[:print:]]//g')
#printf "\033[01;36m"
aaa=$(echo "$1"|awk 'END{print index($0,"s")}')
if (($aaa > 0))
	then
		exit
fi
#echo "$rr"|more
echo "$rr" >| "/tmp/lastLyrics"
