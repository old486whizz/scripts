#!/bin/ksh

if [[ -e $1 ]]
then

	cat $1 | {
	while read LINE
	do
		if [[ `echo $LINE |awk -F . '{print $2}'` = "mp3" ]] &&
		[[ `echo $LINE |awk -F " - " '{print $3}'` = "" ]] &&
		[[ `echo $LINE |awk -F " - " '{print $2}'` != "" ]]
		then
			artist=`echo $LINE | awk -F . '{print $1}'|awk -F " - " '{print $1}'`
			song=`echo $LINE | awk -F . '{print $1}'|awk -F " - " '{print $2}'`
			echo "${artist}===${song}"
			id3v2 -D "${LINE}"
			id3tag -1 -a"${artist}" -s"${song}" "${LINE}"
			echo "named ${LINE} as [${artist}] - [${song}]" >> succ.log
		else
			echo "ERROR with ${LINE}"
			echo "=========" >> error.log
			echo ${LINE}  >> error.log
			echo $LINE |awk -F "-" '{print $3}' >> error.log
			echo $LINE |awk -F . '{print $2}' >> error.log
			echo "=========" >> error.log
		fi
	done
	}
else
	echo "$1 doesn't exist!"
fi
