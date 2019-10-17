#!/bin/bash

while true ; do
    sleep 30
    msg1=$(
        journalctl -q --user-unit onedrive \
        |tail -1 \
        |grep 'onedrive.service: Failed with result'
    )
    msg2=$(
        journalctl -q --user-unit onedrive \
        |tail -1 \
        |awk -F: '{print $NF}'
    )
    [[ "$msg2" == "}" ]] && echo "$msg2" >> "/tmp/.onedriveMonitor"
    if ! [[ -z "$msg1" ]] ; then
        systemctl --user restart onedrive
        echo "$(date '+%a %d %h %Y %H:%M:%S') : restarting onedrive"
        echo "$(date '+%a %d %h %Y %H:%M:%S') : restarting onedrive" >> "/tmp/.onedriveMonitor"
    fi
done


