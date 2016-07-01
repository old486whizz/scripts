#! /usr/bin/bash

# Version 1.0
# Coded by Paul Sanders
# Needs some minor code to actually raise alerts, or produce an error
# Although the script functionally works
# May also need some tweaking to the settings (minutes, number of falls below a certain percentage, etc)

DATE=`date  +%Y%m%d_%H%M`
TIME_P_30=`echo one|awk '{var=(systime()+1800);print strftime("%Y%m%d%H%M",var)}'`
NEW_ALERTS=0

STATS_FILE="/webmethods/IntegrationServer/logs/"
OUTPUT_DIR="/work/"
OUTPUT_FILE="OUTPUT_${DATE}"
ALERTING_DIR="/webmethods_alerts/"
ALERTING_PERIOD=30
# Alerting period so only once every 30 minutes

awk '
BEGIN{
# Init alerting level to below 17%
# alerting num to 3 times
# start_time is now minus 10 minutes

	found_alerts=0
	alerting_num=3
	alerting_level=17
	start_time=(systime()-600)
}
/^2...-..-../ && NF > 8 && !/REQ/ {
# Only if line is correct format

	split($1,date,"-")
	split($2,time,":")
	line_time=mktime(date[1]" "date[2]" "date[3]" "time[1]" "time[2]" "time[3])
# Turn date/time in input line into second-timestamp

	if ( line_time > start_time ) {
		hexTOTAL="0x"$4
		hexFREE="0x"$5
		TOTAL=strtonum(hexTOTAL)
		FREE=strtonum(hexFREE)
		per=(FREE*100)/TOTAL
		if ( per < alerting_level ) {
			found_alerts+=1
			alert_time[found_alerts]=$1,$2
		}
	}
}
END{
	if ( found_alerts > alerting_num ) {
		print "** MEMORY HAS FALLEN",found_alerts,"TIMES IN THE LAST 10 MINS! **\nTimes:\n"
		for ( alert in alert_time ) { print alert_time[alert] }
	}
}' ${STATS_FILE} > ${OUTPUT_FILE}

if [[ $? != 0 ]]; then
	# ERROR IN PROCESSING
fi

[[ -s ${OUTPUT_FILE} ]] && mv ${OUTPUT_FILE} ${ALERTING_DIR}

NEW_ALERTS=`find ${ALERTING_DIR} -type f -newer ${ALERTING_DIR}time |wc -l`
# Find new alerts after the marker file

if (( ${NEW_ALERTS} > "0" )); then
	# ALERT THROUGH PMR
	touch -t ${TIME_P_30} ${ALERTING_DIR}time
	# If newer files found, alert and change marker file to add 30 minutes to any new alerts.
fi


