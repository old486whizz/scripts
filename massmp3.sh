#! /bin/bash
AWK="./| - |.mp3"

find . -maxdepth 1 -name "*.mp3"|while read LINE
do
	ARTIST=`echo ${LINE} |awk -F '/| - |.mp3' '{print \$2}'`
	SONG=`echo ${LINE} |awk -F '/| - |.mp3' '{print \$3}'`
	echo "${LINE}"
	id3v2 -D "${LINE}"
	echo " \-ARTIST: ${ARTIST}"
	echo " \-SONG:   ${SONG}" && echo
	id3v2 -a "${ARTIST}" -t "${SONG}" "${LINE}"

	if [[ "./${ARTIST} - ${SONG}.mp3" != "${LINE}" ]]
	then
		echo "PROBLEM: ${LINE}"
	fi
done
