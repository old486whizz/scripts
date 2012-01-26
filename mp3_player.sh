#! /bin/ksh

#-----------------
# Version 1.0    Jan/2009
#        Picks files at random and copies then to the destination
#        No error checking cos I'm sensible!
#-----------------
# Version 1.1    May/2009
#        Oops, input the wrong way round... D'OH!
#-----------------
# Version 1.5    May/2009
#        Stops copying the same file across twice.
#-----------------
# Version 1.6    Jun/2009
#        Just neatening up the usage info
#-----------------

alias echo='echo -e'
MARKER="==============================\n"
VERSION="1.6"
x=0
SIZE_CP=0

ERR_CHK () {
	if (( $1 != 0 )); then
		echo "ERROR!!"
		exit 2
	fi
}

PRG () {
	while (( ${LENGTH} > 0 )); do
		echo -n "\b"
		((LENGTH-=1))
	done
	echo -n "${PROGRESS}"
}

if (( $# != 2 )); then
	echo "Usage: $0 <destination> <size>		Version: ${VERSION}\n
	destination	- is where the mp3 songs will go
	size		- is the size in MEGS for the script to randomly copy across."
	exit 1
fi

echo "Finding songs in Music directory (no remix/etc)"

find /server/media/Music -maxdepth 1 -type f -exec ls -s {} \; |while read SIZE SONG; do
	SONG_ARR[x]="${SONG}"
	SIZE_ARR[x]="${SIZE}"
	((x+=1))
done

echo "$x songs found.."
echo "Copying $2 Megs across.."

PROGRESS="00/100 0M"
echo -n ${PROGRESS}

((LIMIT=$2*1024))

while (( ${SIZE_CP} < ${LIMIT} )); do
	LENGTH=`echo ${PROGRESS} |wc -c`
	FILE_NO=`echo "$RANDOM%$x" |bc`
	[[ -f "$1/${SONG_ARR[FILE_NO]}" ]] && continue
	cp "${SONG_ARR[FILE_NO]}" "$1"/
	ERR_CHK $?
	((SIZE_CP+=${SIZE_ARR[FILE_NO]}))
	PERCENT=`echo "(100*${SIZE_CP})/${LIMIT}" |bc`
	PROGRESS="${PERCENT}/100 "`echo "${SIZE_CP}/1024" |bc`"M"
	PRG
done

echo "\nsyncing disks.."
sync

echo "DONE!"


