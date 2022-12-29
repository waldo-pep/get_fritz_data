#!/bin/bash
#
# 
#
# read data from frtiz box and write it in a csv file
# tested and developed with my fritzbox 7390 with FRITZ!OS: 06.87!
#
# example call: get_fritz_data.sh

# based on ct script "fritz_docsis_2_influx_lines.sh"
# ---------------------------------------------
# please define your settings for your fritzbox in file "my.credentials"
# ---------------------------------------------
#########################################################################
#
# nothing to be changed from here
#

# get absolute path of script (should be the working dir)
path=`dirname $(realpath $0)`
#echo "$path/my.credentials"
if [ -f "$path/my.credentials" ]; then 
  source $path/my.credentials
else
  echo "no credential file, exit!"
  exit 1
fi

# check if all credentials available
if [ -z "$user" ] || [ -z "$pass" ] || [ -z "$fritzbox" ]; then
  echo "no credentials available, exit!"
  exit 2
fi

# --------------------
# cache Login with SID
# --------------------
sidfile=./$fritzbox.sid
[ ! -f $sidfile ] && echo "0000000000000000" > $sidfile
sid=$(cat $sidfile)

# --------------------
# check Login with SID
# --------------------
result=$(curl -s "http://$fritzbox/login_sid.lua?sid=$sid" | grep -c "0000000000000000")
if [ $result -gt 0 -o $sid = "0000000000000000" ]; then
  challenge=$(curl -s http://$fritzbox/login_sid.lua | grep -o "<Challenge>.*</Challenge>" | sed 's,</*Challenge>,,g')
  hash=$(echo -n "$challenge-$pass" | sed -e 's,.,&\n,g' | tr '\n' '\0' | md5sum | grep -o "[0-9a-z]\{32\}")
  curl -s "http://$fritzbox/login_sid.lua" -d "response=$challenge-$hash" -d 'username='${user} | grep -o "<SID>[a-z0-9]\{16\}" | cut -d'>' -f 2 > $sidfile
fi
sid=$(cat $sidfile)

# no more requests, disable the login 
# (made at the last request to the fritzbox)
last_request="&no_sidrenew"

###################################################################
# get page 'Internet->Online-Monitor' and then card 'Online-Zähler'
# extract counter from today and put it in file 'fritzBox_net.csv'
###################################################################
response=$(curl -s "http://$fritzbox/internet/inetstat_counter.lua" -d "xhr=1&sid=$sid&lang=de&page=docInfo&xhrId=all$last_request")
echo "$response" > inetstat_counter.html
#npx prettier --write inetstat_counter.html 
today_online=$(cat inetstat_counter.html | grep -m 1 "Online-Zeit (hh:mm)" | cut -d ">" -f 2 | cut -d "<" -f 1)
today_sum=$(cat inetstat_counter.html | grep -m 1 "Online-Zeit (hh:mm)" | cut -d ">" -f 4 | cut -d "<" -f 1)
today_send=$(cat inetstat_counter.html | grep -m 1 "Online-Zeit (hh:mm)" | cut -d ">" -f 6 | cut -d "<" -f 1)
today_received=$(cat inetstat_counter.html | grep -m 1 "Online-Zeit (hh:mm)" | cut -d ">" -f 8 | cut -d "<" -f 1)
#echo "$today_online, $today_sum, $today_send, $today_received"
if [ -f "$path/fritzBox_net.csv" ]; then 
  echo "$(date '+%Y-%m-%d');$(date '+%T');$today_online;$today_sum;$today_send;$today_received" >> "$path/fritzBox_net.csv"
else 
  echo "Datum;Zeit;Online-Zeit (hh:mm);Datenvolumen gesamt(MB);Datenvolumen gesendet(MB);Datenvolumen empfangen(MB)" >> "$path/fritzBox_net.csv"
  echo "$(date '+%Y-%m-%d');$(date '+%T');$today_online;$today_sum;$today_send;$today_received" >> "$path/fritzBox_net.csv"
fi

#last_request="&no_sidrenew"
#response=$(curl -s "http://$fritzbox/internet/inetstat_monitor.lua" -d "xhr=1&sid=$sid&lang=de&page=docInfo&xhrId=all$last_request")
#echo "$response" > inetstat_monitor.html
#npx prettier --write inetstat_monitor.html 

