#! /bin/sh

#================================================================
#  <SCRIPT> does the following:
#     * LIST
#   it does NOT:
#     * LIST
#   Assumptions:
#     * LIST
#================================================================
# Version: x.y       DD/MM/20YY       Paul "1" Sanders
#              Basic stuff. I rule,
#              Initial Version Details
# Don't forget to update "VERSION" variable below
# ---
#              FOR INTERNAL USE!!
# 
#================================================================

#================================================================
# Syntax:
#
#   ./<SCRIPT> [-option] <STUFF>
#
#  options:         .
#    o              explain option
#
#  eg.
#    ./<SCRIPT> -o stuff
#
#================================================================


#================================================================
# DEFINITION AREA
#    (basic/global variables + functions)
#================================================================
if [[ "${SHELL}" = "/bin/ksh" ]]; then
  set -A argsarr -- $@
elif [[ "${SHELL}" = "/bin/bash" ]]; then
  shopt -s xpg_echo
  typeset -a 'argsarr=("$@")'
fi
DATESTAMP="`date +%Y%m%d_%H%M%S`"
VERSION="x.y"
SCRIPTHOME="/location"
LOGDIR="${SCRIPTHOME}/logs"

usage () {
  echo "V.${VERSION}"
  echo "usage: <SCRIPT> -o <STUFF>\n"
  echo "options:"
  echo "  -o            | explain option"
  echo ""
  exit 12
}


#================================================================
# Simple validation of parameters:
#================================================================

INDEX=1

while [[ ${OPTIND} -le $# ]]; do
  getopts ":o:" FLAG
  # first : silences unknown flag errors (handled by '?' instead)
  # : after letter indicates parameter value passed after letter
  case ${FLAG} in
    o) OPTION=${OPTARG}
      ;;
    ?) [[ -z ${OPTARG} ]] && value[INDEX]=${argsarr[(OPTIND-1)]} && ((INDEX+=1))
       [[ -n ${OPTARG} ]] && echo "** option: '${OPTARG}' not recognized - ignoring. **" && continue
       ((OPTIND+=1))
      ;;
    :) echo "** option: ${OPTARG} needs an argument. **"
       usage
      ;;
  esac
done

((INDEX-=1))

#================================================================
# Main Script:
#================================================================
# use value[#] to access the parameters passed to the script
