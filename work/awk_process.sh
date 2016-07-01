#! /usr/bin/ksh

echo "ASUP
BSUP1
BSUP2
BSUP3
DSUP
OSUP
NSUP
JSUP1
JSUP2" >>suppliers.tst

echo "ABC|P0123456|M|SOUT|Z|POOL|20110603100101
SUB|N|X|ASUP|20110530|M
X15|_A|6|0|0|0|0|0|0
X15|_B|4|0|0|0|0|0|0
X15|_D|5|0|0|0|0|0|0
X15|_F|5|0|0|0|0|0|0
X15|_H|5647|9|0|0|0|0|9
X15|_J|2|0|0|0|0|0|0
X15|_K|9|0|0|0|0|0|0
X15|_P|3|0|0|0|0|0|0
SUB|N|X|BSUP1|20110530|M
X15|_H|2|0|0|0|0|0|0
SUB|N|X|BSUP2|20110530|M
X15|_A|45|0|0|0|0|0|0
X15|_B|105|0|0|0|0|0|0
X15|_C|3|1|0|5|0|0|0
X15|_E|1|0|0|0|0|0|0
X15|_F|3|0|0|0|0|0|0
X15|_H|416|4|0|0|0|4|0
X15|_J|1|2|0|0|0|0|2
SUB|N|X|FSUP|20110530|M
X15|_B|2|0|0|0|0|0|0
X15|_C|6|1|0|1|0|0|0
SUB|N|X|OSUP|20110530|M
X15|_A|4|0|0|0|0|0|0
X15|_C|6|1|0|1|0|0|0" >input.file


# -------------------------------------
# start of script

# Grab all supplier names from file to add to list:
awk -F'|' '/^SUB/{print $4}' suppliers.tst >/tmp/new_suppliers.$$

# sort suppliers into temporary file:
sort -u /tmp/new_suppliers.$$ suppliers.tst >/tmp/suppliers_sorted.$$
cat /tmp/suppliers_sorted.$$ >suppliers.tst
# should error check this bit


awk -F'|' 'BEGIN{
  # split letters into an array (number of letters in letters_cnt):
  letters_req="0 A B C D E F G H I J K L M N O P"
  letters_cnt=split( letters_req, letters_list, " " )

  # load up supplier list before going through file (awk arrays start at 1)
  i=1
  while ( getline line < "suppliers.tst" ){
    supplier_list[i]=line
    i++
  }
  supplier_cnt=i
}

/^SUB/{
# if I start with SUB:
  supplier_name=$4
  data_array[supplier_name"_0"]=$0
  example_sub=$0
  sub($4,"x_x_x_x",example_sub)
  next
}

/^X15/{
# if X15 record:
  if ( supplier_name == "" ) {
    print "ERROR!! X15 record before supplier name"
    exit 2
  }

  # Create array entry like "ISUP_A" etc, which holds the WHOLE line:
  data_array[supplier_name$2]=$0
  next
}

{
# if not supplier or record lines, then just echo them out?
  print $0
}
END{
  for ( i=1; i < supplier_cnt; i++ ) {
    indexval=supplier_list[i]"_0"
    if ( data_array[indexval] != "" ){
      print data_array[indexval]
    } else {
      output_sub=example_sub
      sub("x_x_x_x",supplier_list[i],output_sub)
      print output_sub
    }
    for ( j=2; j <= letters_cnt; j++ ) {
      indexval=supplier_list[i]"_"letters_list[j]
      if ( data_array[indexval] != "" ){
        print data_array[indexval]
        continue
      }
      print "X15|_"letters_list[j]"|0|0|0|0|0|0|0"
    }
  }
}' input.file

