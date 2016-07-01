#! /bin/ksh

# ====================
# Written by Paul 1 Sanders for Dan Hawley
# Purpose: to ignore headers of files, and copy 1 of each unique file to a destination.
# Hopefully pring out a quick summary
# ====================

error_check ()
{
  if [ "$1" != 0 ]; then
    echo ">>>WARNING - $2 Failed, return code was $1"
    exit $1
  else
    echo "$2 Complete OK\n"
  fi
}

mkdir copies original

for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "this file is unique" >> a$i.file
  echo "this file is special" >> a$i.file
  echo "this file must survive!" >> a$i.file
  if (( $i > 8 )); then
    echo "this is different to the rest" >> a$i.file
  fi
done

for i in 1 2 3 ; do
  echo "this line doesn't matter!" >> b$i.file
  echo "this file is special" >> b$i.file
  echo "this file must survive!" >> b$i.file
done

for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "this file is uniqueiest" >> c$i.file
  echo "this file is special but not alone" >> c$i.file
  echo "this file can only survive!" >> c$i.file
  if (( $i > 8 )); then
    echo "this is differenter" >> c$i.file
  fi
done


SOURCE="./"         # Source for files
DEST="./original/"  # Destination for unique copies to go
MIRROR="./copies/"  # Destination for copies of the unique files
TYPE="*.file"       # Filetype - you can set this to whatever you want (possibly *[0-9]* would be a good alternative)
ARRAY[0]=""         # Simply start off the array.. Not needed in ksh but good habits
x=0                 # index for array

MATCH=0
UNIQUE=0
TOTAL=`find ${SOURCE} -type f -name "${TYPE}" |grep -vE "${DEST}|${MIRROR}" |wc -l`
PROCESSED=0

echo "We have a total of: ${TOTAL} to process."
echo ". is a unique file"
echo "- is a matched file"
echo "Starting: \c"

find ${SOURCE} -type f -name "${TYPE}" |grep -vE "${DEST}|${MIRROR}" |while read FILE; do
  # Find all files with name - ignoring
  VAR=$(tail +2 ${FILE} |cksum)                   # get checksum of file contents
  result=$(echo "${ARRAY[@]}" |grep -c "${VAR}")  # normally I do surrounding quotes - too many escapes here
                                                  # check for previous existence of checksum
  if [[ ${result} = 0 ]]; then
    # File not in array already
    # Add unique to array + move file
    ARRAY[$x]="${VAR}"
    ((x+=1))
    mv ${FILE} ${DEST}
    ((UNIQUE+=1))
    echo ".\c"
  else
    mv ${FILE} ${MIRROR}
    ((MATCH+=1))
    echo "-\c"
  fi
  ((PROCESSED+=1))

done

echo "\n\nWe've processed: ${PROCESSED} files"
echo "Unique files: ${UNIQUE}"
echo "Matches: ${MATCH}"


