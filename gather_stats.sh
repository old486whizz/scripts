#! /bin/ksh

#================================================================
#  gather_stats does the following:
#     * collects info from a list of servers:
#        - CPU
#        - MEMORY
#        - sse_service_status
#        - sandpit
#        - ifconfig -a
#        - netstat -rn
#        - mount
#        - showmount -e
#        - lspath
#        - vios (lsmap -fmt)
#        - HMC running profile name
#        - ps -ef
#        - lsdb -s
#     * generates 3 profile start scripts (vio/dev/prod)
#     * generates 1 dev unsandpitting script
#   it does NOT:
#     * compare them
#   assumptions:
#     * dev is the only one that needs an unsandpitting script
#     * strictly named lpars (ie {hav|por}u{a|d}[0-9][0-9][0-9] )
#================================================================
# Version: 1.0       01/02/2012       Paul "1" Sanders
#              Basic stuff. I rule,
#              Initial Version Details
#              This was very rushed... There could be better ways to do this code.
# Don't forget to update "VERSION" variable below
# ---
#              FOR INTERNAL USE!!
# 
#================================================================

#================================================================
# Syntax:
#
#   ./gather_stats.sh {-H|-P}[0-9].. [-d]
#
#  options:         .
#    -d             Debugging (leaves files behind, sometimes verbose stuff)
#    -H             Havant     P-series
#    -P             Portsmouth P-series
#    [0-9]          P-series number
#
#  eg.
#    ./gather_stats.sh -H7
#
#================================================================


#================================================================
# DEFINITION AREA
#    (basic/global variables + functions)
#================================================================
trap prc_exit 1 2 3 4 5 6 7 8 9 10
DATESTAMP="`date +%Y%m%d_%H%M%S`"
VERSION="1.0"
SCRIPTHOME="`dirname $0`"
RESULTSDIR="${SCRIPTHOME}/results_${OPT}_${DATESTAMP}"
TMPDIR="/tmp/GS.$$"
OPT=N
DEBUG=0

prc_exit () {
  [[ ${DEBUG} != 1 ]] && echo "Tidying up temp files" && rm -fr ${TMPDIR} >/dev/null 2>&1
  exit $1
}

usage () {
  echo "V.${VERSION}"
  echo "usage: gather_stats.sh {-H|-P}[0-9].. [-d]\n"
  echo "options:"
  echo "  -d            | Debugging (leaves files behind, sometimes verbose stuff)"
  echo "  -H            | Havant     P-series"
  echo "  -P            | Portsmouth P-series"
  echo "  [0-9]         | P-series number"
  echo ""
  echo "eg."
  echo "  ./gather_stats.sh -H7"
  echo ""
  prc_exit 12
}


#================================================================
# Simple validation of parameters:
#================================================================

INDEX=1
set -A argsarr -- $@

while [[ ${OPTIND} -le $# ]]; do
  getopts ":H:P:d" FLAG
  # first : silences unknown flag errors (handled by '?' instead)
  # : after letter indicates parameter value passed after letter
  case ${FLAG} in
    H)  OPT="H${OPTARG}"
      ;;
    P)  OPT="P${OPTARG}"
      ;;
    d)  DEBUG=1
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

if [[ "${OPT}" == "N" ]]; then
  usage
fi


#================================================================
# Get frame details (ie, all servers etc)
#================================================================
case ${OPT} in
  H7)
    HMC="havli001"
    FRAME="H7_9119-FHA-SN83B78C5"
    # could possibly put VIO list here to be more accurate)
    ;;
  *)
    echo "NOT SUPPORTED YET (just needs info on the P-series frame)"
    prc_exit 23
    ;;
esac

mkdir ${TMPDIR}
mkdir ${RESULTSDIR}

# Get all lpars
ssh hscroot@${HMC} "lssyscfg -m ${FRAME} -r lpar -F name,curr_profile,state" >${TMPDIR}/hmc.complete.list

# Get the running servers
awk '/^[hp][ao][vr]u[ad][0-9][0-9][0-9].*Running$/{print substr($1,1,8)}' ${TMPDIR}/hmc.complete.list >${TMPDIR}/hmc.da_running.list

# Get running infrastructure (usually VIOs)
awk '/^[hp][ao][vr]ui[0-9][0-9][0-9].*Running$/{print substr($1,1,8)}' ${TMPDIR}/hmc.complete.list >${TMPDIR}/hmc.i_running.list

# These are server we do nothing with
grep -vf ${TMPDIR}/hmc.da_running.list -vf ${TMPDIR}/hmc.i_running.list ${TMPDIR}/hmc.complete.list |awk -F ' |,' '{print $1}' >${TMPDIR}/hmc.BAD.list

# Get UI servers first, then ua/ud
grep -f ${TMPDIR}/hmc.i_running.list ${TMPDIR}/hmc.complete.list |awk -F' |,' '{print substr($1,1,8)" has a running profile of: "$NF}' >${RESULTSDIR}/hmc.running.profiles
grep -f ${TMPDIR}/hmc.i_running.list ${TMPDIR}/hmc.complete.list |awk -F',' '{print "chsysstate -m '${FRAME}' -r lpar -o on -n \""$1"\" -f "$(NF-1)" -b normal &"}' > ${RESULTSDIR}/hmc.startup.profiles

grep -f ${TMPDIR}/hmc.da_running.list ${TMPDIR}/hmc.complete.list |awk -F' |,' '{print substr($1,1,8)" has a running profile of: "$NF}' >>${RESULTSDIR}/hmc.running.profiles
grep -f ${TMPDIR}/hmc.da_running.list ${TMPDIR}/hmc.complete.list |awk -F',' '{print "chsysstate -m '${FRAME}' -r lpar -o on -n \""$1"\" -f "$(NF-1)" -b normal &"}' >> ${RESULTSDIR}/hmc.startup.profiles


#================================================================
# Get VIO details (lsmap)
#================================================================

echo "SERVERS NOT BEING DONE:\n------------------"
cat ${TMPDIR}/hmc.BAD.list
echo "------------------\n"

cat ${TMPDIR}/hmc.i_running.list |wc -l |read vio_count
COUNT=1

cat ${TMPDIR}/hmc.i_running.list |while read VIONAME; do
  echo "[${COUNT}/${vio_count}]: ${VIONAME}"
  ((COUNT+=1))
  # Get lsmap listing
  ssh -n ${VIONAME} '[[ -f /usr/ios/cli/ioscli ]] && /usr/ios/cli/ioscli lsmap -all -field clientid svsa backing vtd -fmt :' >${RESULTSDIR}/vio.${VIONAME}.lsmap
  # Remove file if it's empty (which means no disks are presented)
  [[ ! -s ${RESULTSDIR}/vio.${VIONAME}.lsmap ]] && rm ${RESULTSDIR}/vio.${VIONAME}.lsmap

done

cat ${TMPDIR}/hmc.i_running.list ${TMPDIR}/hmc.da_running.list |wc -l |read svr_count
COUNT=1

cat ${TMPDIR}/hmc.i_running.list ${TMPDIR}/hmc.da_running.list |while read SERVNAME; do
  echo "[${COUNT}/${svr_count}]: ${SERVNAME}"
  ((COUNT+=1))
  # Get lparstat (ram/cpu/etc)
  ssh -n ${SERVNAME} 'lparstat -i' >${RESULTSDIR}/svr.${SERVNAME}.lparstat 
  
  # Get lspv
  ssh -n ${SERVNAME} 'lspv' >${RESULTSDIR}/svr.${SERVNAME}.lspv
  
  # Get other stuff like network/mounted stuff
  ssh -n ${SERVNAME} 'lspath; ifconfig -a; netstat -rn; mount; showmount -e 2>/dev/null' >${RESULTSDIR}/svr.${SERVNAME}.cmds
  
  # Get sse_service_status
  ssh -n ${SERVNAME} 'sse_service_status' |awk '!/^S/{print $1,$2}' >${RESULTSDIR}/svr.${SERVNAME}.sse_service_status
  
  # Get quick process listing
  ssh -n ${SERVNAME} 'ps -eF user,args |sort' >${RESULTSDIR}/svr.${SERVNAME}.ps_eF
  
  # If we have an oracle user - why not try lsdb?
  ssh -n ${SERVNAME} 'lsuser -a oracle >/dev/null 2>&1 && su - oracle -c "lsdb -s" 2>/dev/null' >${RESULTSDIR}/svr.${SERVNAME}.lsdb
  # Remove file if it's empty (which means no databases are presented)
  [[ ! -s ${RESULTSDIR}/svr.${SERVNAME}.lsdb ]] && rm ${RESULTSDIR}/svr.${SERVNAME}.lsdb
  
  return="`sse server_info ${SERVNAME}|awk '/is a.*host/{print $4}'`"
  case ${return} in
     "DEVELOPMENT") MUM_STAT="D" ;;
     "LIVE")        MUM_STAT="P" ;;
     *)             MUM_STAT="S" ;;
  esac
  echo "${SERVNAME} ${MUM_STAT}" >>${RESULTSDIR}/svr.running.mum 
  
done

prc_exit 0

