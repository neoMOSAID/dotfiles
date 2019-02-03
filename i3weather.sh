#!/bin/bash
ping -c 1 8.8.8.8 2>&1 |grep unreachable >/dev/null
code=$?
if (( code == 0 )) ; then
    echo null
    echo
    echo "#b6fcd5"
    exit
fi

if (( "$BLOCK_BUTTON" == 1 )) ; then
    notify-send "getting weather data..."
    pkill -RTMIN+8 i3blocks
fi

function CURL() {
  userAgent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:48.0) "
  userAgent+="Gecko/20100101 Firefox/48.0"
  curl -s -A "$userAgent"  -e https://www.accuweather.com "$@"
}

url="https://www.accuweather.com/en/ma/el-ksiba/246068/weather-forecast/246068"

data="$(
        CURL "$url" \
        |grep 'acm_RecentLocationsCarousel.push' \
        |head -1 \
        |sed 's/acm_RecentLocationsCarousel.push//' \
        |tr -d '();' \
        |tr -d '{}' \
        |sed "s/,/-/;s/:/=/g;s/,/\n/g;s/[\"\']*//g;s/[\t ]*//g" \
        |jo
      )"

city="$( echo "$data" | jq '.name' | sed 's/-Morocco//' |sed 's/"//g' )"
temp="$( echo "$data" | jq '.temp' | sed 's/-Morocco//' |sed 's/"//g' )"

echo $city $temp°C
echo
echo "#b6fcd5"


