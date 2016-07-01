#! /usr/bin/ksh93

typeset -A one two
one=( [red]=ball [green]=grass [blue]=sky )
two=( [red]=light [green]=go [blue]=face )

echo "this is ksh93!"
echo "assoc arrays:"
echo "${!one}: ${!one[@]}"
echo "${!two}: ${!two[@]}"

outer=one
inner=red

echo "one[red]=${one[red]}"
echo "two[red]=${two[red]}"
echo "$outer[$inner]=`eval echo \\${$outer[$inner]}`\n"

echo "pointing test at $outer:"
typeset -n test=$outer
echo "test[red]=${test[red]}"

function three.set {
  let .sh.value=${.sh.value}+1
}

three=0
echo "$three"
three=1
echo "$three"

set -x
typeset -A test2
test2=( [${outer}_${inner}]="wahooo" )
set |grep -i test

