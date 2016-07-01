#!/usr/bin/ksh

#./psan.sh
# creates "OUTPUT" file

for file in `ls *log`; do
   echo "Processing: ${file}"
   echo "********************************"

   awk 'BEGIN {
        ERR=0
        DESC=0
        memory=0
        hresult=0
        network=0
        reference=0
        failed=0
        no_ok=0}
{
        if ($1~/Error/ && ERR==0) {ERR=$2}
        if ($1~/Description/ && DESC==0) {DESC=$0}

        if ($0~/^Desc.*Out of server memory/) memory++
        if ($0~/^Desc.*HRESULT/) hresult++
        if ($0~/^Desc.*Network/) network++
        if ($0~/^Desc.*reference not/) reference++

        if ($NF~/OK/) {
          if (ERR==0) {
            print
            no_ok++}
          else if (DESC~/Out of server memory|HRESULT|Network|reference not/)
            {print $1,"\n", ERR, "\n", DESC, "\n"
            failed++}
          ERR=0
          DESC=0
        }}
END {
        print "==================\nTOTALS:\n"
        print "OK =", no_ok
        print "FAILED =", failed
        print "------------------"
        print "The following sub-totals contain multiple errors against a single fasset"
        print "------------------"
        print "Out Of Memory =", memory
        print "HRESULT =", hresult
        print "Network =", network
        print "Reference =", reference
        print "==================\n"
/ /g'   }' ${file} |sed 's/
done > OUTPUT

awk -F'=' 'BEGIN{
        ok=0
        fail=0
        memory=0
        hresult=0
        network=0
        reference=0}
{       if ($0~/ = /) {
          if ($1~/OK/) {ok+=$2}
          if ($1~/Memory/) {memory+=$2}
          if ($1~/Network/) {network+=$2}
          if ($1~/Reference/) {reference+=$2}
          if ($1~/HRES/) {hresult+=$2}
          if ($1~/FAIL/) {failed+=$2}
        }}
END{
        print "===============\nALL FILES TOTALS:\n"
        print "OK =", ok
        print "FAILED =", failed
        print "------------------"
        print "The following sub-totals contain multiple errors against a single fasset"
        print "------------------"
        print "Out Of Memory =", memory
        print "HRESULT =", hresult
        print "Network =", network
        print "Reference =", reference
        print "==================\n"}' OUTPUT > TEMP

cat TEMP >> OUTPUT
rm TEMP

echo "OUTPUT file created."
echo "Creating list.OK and list.FAILED.."

awk '{if ($NF=="OK"){print $1}}' OUTPUT > list.OK
awk 'BEGIN{line=0}
{       if (!($0~/OK|Desc|Numb|=|\*|\-|:|^$/)){
          print $1
          if (line++==100) {
                  print ""
                  line=0
          }
        }}' OUTPUT > list.FAILED

