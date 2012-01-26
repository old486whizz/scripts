#! /bin/ksh

#-----------------
# Version 1.0    Jun/2009
#        cdrdao line grabbed from a ubuntu forum
#        enables me to rip PSX CD's for backup / emulation purposes.
#-----------------

VERSION=1.0
alias echo='echo -e'
SAVEDIR="/server/games/PSX/"

usage () {
	echo "$@"
	echo "Usage: $0 <name>		Version: ${VERSION}\n
	name	- Name to be used for the iso (eg 'Crash_Bandicoot_1' .. '.iso' is appended)
		Stored in directory: ${SAVEDIR}"
	exit 1
}

rip_disc () {
	cdrdao read-cd --device /dev/sr0 --driver generic-mmc-raw --read-raw --datafile $1 $1.toc
	sleep 1
	rm $1.toc
}

[[ "$#" != "1" ]] && usage

FILE="${SAVEDIR}$1.iso"

rip_disc ${FILE}
