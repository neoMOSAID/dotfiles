#!/bin/bash
Atext="\"$(cat /tmp/nextPrayerTimeA 2>/dev/null)\""
Atext=$(python -c"import arabic_reshaper;print(arabic_reshaper.reshape($Atext))")
printf "$Atext"|rev
