#!/bin/ksh
trap "" 1 2 3 4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20
umask 022

# Kick off the users local profile
USER=`whoami`
HOME=`grep ${USER} /etc/passwd |awk -F ':' '{print $6}'`
# Check to see if .PROD file exists in users home directory.

[[ -a ${HOME}/.PROD ]] && . ${HOME}/.PROD
	# Contents of .PROD file - # export PRODUCTION='/usr/users/remacint/make_req.sh'

alias sl=

CONFIG_FILE='/login.conf'
CONFIG='/tmp/tmp.'$$
TR="tr [:lower:] [:upper:]"
MAIN="FALSE"
LOOPS=0

# Vars also used:
#
#    From profile:
#  PRODUCTION  (script for LUA access)
#
#    In Script:
#  SERVERS     (an array of servers read from the temporary config file)
#  SERVER      (single var holding chosen server name)
#  RUSERS      (array of remote users for the specified server
#  NUMBER      (input number from the user)
#  IT          (iterator variabe to index the list)
#  RESULT      (result from the test)
#  USER_SELECT (boolean for the inner loop)
#  LOOPS       (loop variable used so that the program exits after 10 loops)

quit () {
	rm ${CONFIG} 2>/dev/null
	USER_SELECT='FALSE'
	EXIT='TRUE'
	MAIN='TRUE'
}

question () {
	clear
	echo "\n\n$1\n"
}

options () {
	IT=0
	for ENTRY in "$@"
	do
		((IT+=1))
		echo "${IT}. ${ENTRY}"
	done
	echo "\nb. BACK"
	echo "e. EXIT"
	echo "p. PASSWORD"
	echo "\n\n [1..${IT}|E|B|P] $\c"
}

input () {
# Sets:
#  $NUMBER to user input
#  $RESULT to 0 or 1 (successful number or other character)

	read NUMBER
	[[ `echo ${NUMBER} |${TR}` = 'P' ]] && passwd
	command test ${NUMBER} -gt 0 -a ${NUMBER} -le ${IT} 2>/dev/null
	# This kicks off the test command in a sub-shell so that if it errors with the comparison, the error is caught, and the user stays inside the script.

	RESULT=$?
}

process_result () {
# Function takes $RESULT, processes it, and either echos probs and returns 1, or suceed's and returns 0.
# Sets:
#    P_RESULT (0 or 1)

if [[ $RESULT != 0 ]]
then
	echo "That is incorrect!"
	sleep 1
	((LOOPS+=1))
	P_RESULT=1
else
	LOOPS=0
	P_RESULT=0
fi

}

# find all instances of $USER in the file $CONFIG_FILE  and place them in variable $CONFIG
grep ${USER} ${CONFIG_FILE} > ${CONFIG}

# Create array SERVERS and store server names grep'd from variable $CONFIG (field 2)
set -A SERVERS `grep -v "^#" ${CONFIG} |awk '{print $2}'|${TR} | awk '! a[$0]++'`

while [[ ${MAIN} != 'TRUE' && $LOOPS -lt 10 ]]
do
{
	EXIT=FALSE	# to fix 'BACK' functionality.
	if [[ "${PRODUCTION}" != "" ]]
	then
		while [[ ${MAIN} != 'TRUE' ]]
		do
			question "Which type of server do you wish to log in to?"
			options "Production" "Development"
			input

			[[ `echo ${NUMBER} |${TR}` = 'E' ]] && quit
			[[ ${NUMBER} = 1 ]] && ${PRODUCTION} && quit
			[[ ${NUMBER} = 2 ]] && break
		done
	fi

	while [[ ${EXIT} != 'TRUE' && $LOOPS -lt 10 ]]
	do
	{
		if (( ${#SERVERS[*]} < 1 ))
		then
			echo "\nYou don't have access to any servers. Please contact your UNIX Administrators."
			read
			quit && continue
		fi

		question "Which server do you wish to log into?"
		options ${SERVERS[*]}
		input

		[[ `echo ${NUMBER} |${TR}` = 'B' ]] && USER_SELECT='FALSE' && EXIT='TRUE' && continue
		[[ `echo ${NUMBER} |${TR}` = 'E' ]] && quit && continue

		process_result
		if [[ $P_RESULT = 0 ]]
		then
			((NUMBER-=1))
			SERVER=${SERVERS[NUMBER]}
			USER_SELECT='TRUE'
		fi #end if RESULT

		while [[ ${USER_SELECT} = 'TRUE' && $LOOPS -lt 10 ]]
		do
		{
			#Create array RUSERS and store results of grep of variable $CONFIG matching variable 
			#$SERVER selecting the username (field 3)
			set -A RUSERS `grep -v "^#" ${CONFIG} |grep -i ${SERVER} |awk '{print $3}' |tr ',' ' '`

			if [[ ${#RUSERS[*]} = 1 ]]
			then
				echo "Please wait!"
				sl ${SERVER} ${RUSERS[*]}
				USER_SELECT='FALSE'
			fi #end if RUSERS

			question "[${SERVER}]-> Please select a username:"
			options ${RUSERS[*]}
			input

			[[ `echo ${NUMBER} |${TR}` = 'B' ]] && USER_SELECT='FALSE' && continue
			[[ `echo ${NUMBER} |${TR}` = 'E' ]] && quit && continue

			process_result
			if [[ $P_RESULT = 0 ]]
			then
				echo "Please wait!"
				((NUMBER-=1))
				sl ${SERVER} ${RUSERS[NUMBER]}
			fi
		}
		done
	}
	done
}
done
