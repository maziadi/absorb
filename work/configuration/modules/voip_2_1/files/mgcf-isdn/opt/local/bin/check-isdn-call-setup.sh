#!/bin/bash

function check() {
  chanseq=$(echo $(seq $1 $2) | tr -s ' ' '|')
  logencours=$(cat /var/log/syslog | awk "
BEGIN { cstart=0; cend=0 }
/Parsing.*chan_dahdi.conf/ { cstart=0; cend=0 }
/DAHDI\/(${chanseq})-.*proceeding passing/ { cstart+=1 }
/Hungup.*DAHDI\/(${chanseq})-/ { cend+=1 }
END { print cstart - cend }") 
  echo $1-$2: $logencours
}

for((i=0;i<7;i++))
do
  x=$(expr 1 + $(expr $i '*' 31))
  y=$(expr 30 + $x)
  check $x $y
done
