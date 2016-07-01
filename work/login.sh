#! /bin/ksh
#=====================================
# Coded by the almighty Paul Sanders
# Date: Around April-ish 2008
#
# Script to control the access for DEVELOPMENT / TEST systems
#
# CONFIG_FILE='${CONFIGDIR}/login.conf'
#=====================================
#
#=====================================


VERSION="2.0"

trap "" 2 3 4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20
trap quit 1
umask 022

# Kick off the users local profile
USER=$(whoami)
HOME=$(awk -F ':' '/'${USER}'/{print $6}' /etc/passwd)
DEBUG=0
alias sl=$SSH_WRAPPER

# Check to see if .custom file exists in users home directory.

[[ -f ${HOME}/.custom ]] && . ${HOME}/.custom
# Contents of .custom file:
#  "export CUSTOM='${REQUEST_SCRIPT}' "


CONFIG_FILE='${CONFIGDIR}/login.conf'
CONFIG='/tmp/tmp.'$$
TR="tr [:lower:] [:upper:]"
DEPTH=1
P1PID=$$
MINSRUNNING=0

# Vars also used:
#
#    From profile:
#  CUSTOM   (script for custom access)
#
#    In Script:
#  SERVERS      (an array of servers read from the temporary config file)
#  SERVER       (single var holding chosen server name)
#  RUSERS       (array of remote users for the specified server)
#  NUMBER       (input number from the user)
#  IT           (iterator variabe to index the list)
#  RESULT       (result from the test)
#  USER_SELECT  (boolean for the inner loop)
#  DEBUG        (allow debug output)

quit () {
  rm ${CONFIG} 2>/dev/null
  DEPTH=0
}

days_7 () {
  while (( ${MINSRUNNING} < 10000 )); do
    sleep 60
    ((MINSRUNNING+=1))
  done
  quit
  kill -9 $1
}

question () {
  clear
  echo "Single Log In for Multiple Systems (S.L.I.M.S)\nVersion: ${VERSION}"
  echo "\n\n$1\n"
}

options () {
  IT=0
  for ENTRY in "$@"; do
    ((IT+=1))
    echo "${IT}. ${ENTRY}"
  done
  echo "\nb. BACK"
  echo "e. EXIT"
  echo "p. PASSWORD"
  echo "\n\n [1..${IT}|E|B|P] $ \c"
}

input () {
# Sets:
#  $NUMBER to user input
#  $RESULT to 0 or 1 (successful number/letter _or_ other character)
#  RETURN 0 or 1 (succ input _or_ run continue)

  read NUMBER
  command test ${NUMBER} -gt 0 -a ${NUMBER} -le ${IT} 2>/dev/null
  # This kicks off the test command in a sub-shell so that if it errors with the comparison, the error is caught, and the user stays inside the script.

  RESULT=$?

  [[ `echo ${NUMBER} |${TR}` = 'P' ]] && passwd
  [[ `echo ${NUMBER} |${TR}` = 'B' ]] && go_back && return 1
  [[ `echo ${NUMBER} |${TR}` = 'E' ]] && quit && return 1
  [[ ${DEPTH} = 1 ]] && return 0

  if [[ ${RESULT} != 0 ]]; then
    echo "That is incorrect!"
    sleep 1
    return 1
  else
    return 0
  fi

}

go_back () {
# Simple function to go back one menu level

  [[ ${DEPTH} = 1 ]] && DEPTH=1 || ((DEPTH-=1))

}

connect () {
# connect to destination
# PARAMS:
# $1 = number from RUSERS array

  echo "Please wait!"
  sl ${SERVER} ${RUSERS[$1]}

}

DEBUG_OUT () {
  echo " = = = = DEBUG = = = ="
  echo $@
  echo " = = = = DEBUG = = = ="
  read
}

# find all instances of $USER in the file $CONFIG_FILE  and place them in variable $CONFIG
# Create array SERVERS and store server names grep'd from variable $CONFIG (field 2)
grep ${USER} ${CONFIG_FILE} > ${CONFIG}
[[ "1" = "$DEBUG" ]] && DEBUG_OUT `grep ${USER} ${CONFIG_FILE}|sed 's/$/\\\\n/g'`
set -A SERVERS `awk '!/^#/{print toupper($2)}' ${CONFIG}| awk '! a[$0]++'`

days_7 ${P1PID} &

if (( ${#SERVERS[*]} < 1 )); then
  echo "\nYou don't have access to any servers. Please contact your UNIX Administrators."
  read
  quit
fi

while [[ ${DEPTH} > 0 ]]
do
  [[ "${CUSTOM}" != "" ]] || DEPTH=2
  while [[ ${DEPTH} = 1 ]]; do
    question "Which type of server do you wish to log in to?"
    options "Production" "Development"
    input

    [[ ${NUMBER} = 1 ]] && ${CUSTOM} && quit
    [[ ${NUMBER} = 2 ]] && DEPTH=2
  done

  while [[ ${DEPTH} = 2 ]]; do
    question "Which server do you wish to log into?"
    [[ "1" = "$DEBUG" ]] && DEBUG_OUT `echo ${SERVERS[*]}`
    options ${SERVERS[*]}
    input || continue

    ((NUMBER-=1))
    SERVER=${SERVERS[NUMBER]}
    set -A RUSERS `awk '!/^#/{if (toupper($2)~/'${SERVER}'/){print $3}}' ${CONFIG} |tr ',' ' '`
    DEPTH=3

    while [[ ${DEPTH} = 3 ]]; do
      #Create array RUSERS and store results of grep of variable $CONFIG matching variable
      #$SERVER selecting the username (field 3)
      [[ ${#RUSERS[*]} = 1 ]] && connect 0 && go_back && continue

      question "[${SERVER}]-> Please select a username:"
      options ${RUSERS[*]}
      input || continue

      ((NUMBER-=1))
      connect ${NUMBER}
    done
  done
done

