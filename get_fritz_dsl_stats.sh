#!/bin/bash
#
# 
#
# read data from frtiz box and write it in a csv file
#
# example: get_fritz_data.sh

# based on ct script "fritz_docsis_2_influx_lines.sh"
# ---------------------------------------------
# please define your settings for your fritzbox
# ---------------------------------------------
source my.credentials

path="/home/otti/get_fritz_data"

#
# nothing to be changed from here
#

if [ -z "$user" ] || [ -z "$pass" ] || [ -z "$fritzbox" ]; then
  echo "no credetials available, exit!"
  exit 1
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

# --------------------------------
# read DOCSIS-Infos (page=docInfo)
# --------------------------------
#docsis=$(curl -s "http://$fritzbox/data.lua" -d "xhr=1&sid=$sid&lang=de&page=docInfo&xhrId=all&no_sidrenew")

#echo "docsis=$docsis"

#my_docsis=$(curl -s "http://$fritzbox/internet/dsl_spectrum.lua" -d "xhr=1&sid=$sid&lang=de&page=docInfo&xhrId=all&no_sidrenew" -H "Content-Type:application/json")
#my_docsis=$(curl --insecure -d "sid=$sid&lang=de&page=docInfo&" -X POST "http://$fritzbox/data.lua")

#response=$(curl -s "http://$fritzbox/internet/dsl_stats_tab.lua" -d "xhr=1&sid=$sid&lang=de&page=docInfo&xhrId=all")
#echo "$response" > dsl_stats_tab.html
#npx prettier --write dsl_stats_tab.html 

#response=$(curl -s "http://$fritzbox/internet/dsl_stats_graph.lua" -d "xhr=1&sid=$sid&lang=de&page=docInfo&xhrId=all")
#echo "$response" > dsl_stats_graph.html
#npx prettier --write dsl_stats_graph.html 
last_request="&no_sidrenew"

response=$(curl -s "http://$fritzbox/internet/inetstat_counter.lua" -d "xhr=1&sid=$sid&lang=de&page=docInfo&xhrId=all$last_request")
echo "$response" > inetstat_counter.html
#npx prettier --write inetstat_counter.html 
today_online=$(cat inetstat_counter.html | grep -m 1 "Online-Zeit (hh:mm)" | cut -d ">" -f 2 | cut -d "<" -f 1)
today_sum=$(cat inetstat_counter.html | grep -m 1 "Online-Zeit (hh:mm)" | cut -d ">" -f 4 | cut -d "<" -f 1)
today_send=$(cat inetstat_counter.html | grep -m 1 "Online-Zeit (hh:mm)" | cut -d ">" -f 6 | cut -d "<" -f 1)
today_received=$(cat inetstat_counter.html | grep -m 1 "Online-Zeit (hh:mm)" | cut -d ">" -f 8 | cut -d "<" -f 1)
echo "$today_online, $today_sum, $today_send, $today_received"
if [ -f "$path/fritzBox_net.csv" ]; then 
  echo "$(date '+%Y-%m-%d');$(date '+%T');$today_online,$today_sum,$today_send,$today_received" >> "$path/fritzBox_net.csv"
else 
  echo "Datum;Zeit;Online-Zeit (hh:mm);Datenvolumen gesamt(MB);Datenvolumen gesendet(MB);Datenvolumen empfangen(MB)" >> "$path/fritzBox_net.csv"
  echo "$(date '+%Y-%m-%d');$(date '+%T');$today_online;$today_sum;$today_send;$today_received" >> "$path/fritzBox_net.csv"
fi

#last_request="&no_sidrenew"
#response=$(curl -s "http://$fritzbox/internet/inetstat_monitor.lua" -d "xhr=1&sid=$sid&lang=de&page=docInfo&xhrId=all$last_request")
#echo "$response" > inetstat_monitor.html
#npx prettier --write inetstat_monitor.html 

#echo "my_docsis=$my_docsis"
#cat dsl_stats_tab_lua.html |grep DSLAM-Datenrate
#echo $my_docsis
exit
# AVM may change the modulation entry from 'type' to 'modulation' in later OS version
if [ "_"$(echo ${docsis} | jq -r ".data.channelUs.docsis30[0].type") = "_null" ]; then
  qam="modulation"
else
  qam="type"
fi

echo "3 $qam"

# get nr. of up-/downstream channels
channelUs=$(echo ${docsis} | jq ".data.channelUs.docsis30[].powerLevel" | wc -l)
channelDs=$(echo ${docsis} | jq ".data.channelDs.docsis30[].powerLevel" | wc -l)

echo "3.5"

# read upstream channels
for (( c=0; c<$channelUs; c++ )); do
  channelID[$c]=$(echo ${docsis}  | jq -r ".data.channelUs.docsis30[$c].channelID")
  channel[$c]=$(echo ${docsis}    | jq -r ".data.channelUs.docsis30[$c].channel")
  modulation[$c]=$(echo ${docsis} | jq -r ".data.channelUs.docsis30[$c].$qam" | sed 's/[^0-9.]//g')
  powerLevel[$c]=$(echo ${docsis} | jq -r ".data.channelUs.docsis30[$c].powerLevel")
  frequency[$c]=$(echo ${docsis}  | jq -r ".data.channelUs.docsis30[$c].frequency")

  echo "docsis,mode=up,channel=${channelID[$c]} Modulation=${modulation[$c]}"
  echo "docsis,mode=up,channel=${channelID[$c]} PowerLevel=${powerLevel[$c]}"
  echo "docsis,mode=up,channel=${channelID[$c]} Frequenz=${frequency[$c]}"
done

echo "4"


# read downstream channels
for (( c=0; c<$channelDs; c++ )); do
  channelID[$c]=$(echo ${docsis}  | jq -r ".data.channelDs.docsis30[$c].channelID")
  channel[$c]=$(echo ${docsis}    | jq -r ".data.channelDs.docsis30[$c].channel")
  modulation[$c]=$(echo ${docsis} | jq -r ".data.channelDs.docsis30[$c].$qam" | sed 's/[^0-9.]//g')
  powerLevel[$c]=$(echo ${docsis} | jq -r ".data.channelDs.docsis30[$c].powerLevel")
  frequency[$c]=$(echo ${docsis}  | jq -r ".data.channelDs.docsis30[$c].frequency")
  latency[$c]=$(echo ${docsis}    | jq -r ".data.channelDs.docsis30[$c].latency")
  corrErrors[$c]=$(echo ${docsis} | jq -r ".data.channelDs.docsis30[$c].corrErrors")
  nonCorrErrors[$c]=$(echo ${docsis} | jq -r ".data.channelDs.docsis30[$c].nonCorrErrors")

  echo "docsis,mode=down,channel=${channelID[$c]} Modulation=${modulation[$c]}"
  echo "docsis,mode=down,channel=${channelID[$c]} PowerLevel=${powerLevel[$c]}"
  echo "docsis,mode=down,channel=${channelID[$c]} Frequenz=${frequency[$c]}"
  echo "docsis,mode=down,channel=${channelID[$c]} Latenz=${latency[$c]}"
  echo "docsis,mode=down,channel=${channelID[$c]} korrFehler=${corrErrors[$c]}"
  echo "docsis,mode=down,channel=${channelID[$c]} Fehler=${nonCorrErrors[$c]}"
done

echo "finish"
