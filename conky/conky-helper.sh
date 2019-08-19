
if mpc --host=127.0.0.1 --port=6601 |grep -F "[paused]">/dev/null
    then
        echo paused
    else
        echo playing
        exit
fi
pid=$( /home/mosaid/.i3/pplay/play.sh pid )
if ! [[ -z "$pid" ]]
    then
        echo paused
    else
        echo playing
fi
