#! /bin/ksh

find . -name "*mp3" |awk 'BEGIN{i=2}{
	orig=$0
	while (i<=NF){
		rep=toupper(substr($i,1,1))
		sub(/^./,rep,$i)
		i++
	}
	sub(/^.\/[0-9][0-9]/,"-",$0)
	rename="The Shortwave Set "$0
	system ("mv \""orig"\" \""rename"\"")
	i=2}'
