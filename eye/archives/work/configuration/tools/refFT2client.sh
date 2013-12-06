#!/bin/bash

function displayclientname () {
    echo "${atmfile[$1]}" | awk '
/###[#[:space:]]*$/ {
    if (NR < clientline && NR > vispline+1)
        vispline=NR+1
}

{
    if( vispline == NR)
        visp=$0
    else if( clientline == NR )
        client=$0
}

END {
    print visp"\n"client
}' clientline=$2

    return 1
}

#MAIN

[ $# -lt 1 ] && echo "Usage : $0 <refFT> [<refFT> ...]" && exit -1

atmfile[0]=`ssh atmudp-2-cbv1 'cat /etc/network/atmudp'`
atmfile[1]=`ssh atmudp-3-cbv2 'cat /etc/network/atmudp'`
atmfile[2]=`ssh atmudp-4-cbv2 'cat /etc/network/atmudp'`
atmfile[3]=`ssh atmudp-1-ven1 'cat /etc/network/atmudp'`
atmfile[4]=`ssh atmudp-2-ven1 'cat /etc/network/atmudp'`
idmax=2

ref=0
while [ $# -gt 0 ]
    do
    [ "$ref" == "$1" ] && shift
    ref="$1"
    [ -z "${ref}" ] && continue
    [ -z "${ref/[0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z]/}" ] || continue
    
    id=0
    while [ $id -le $idmax ]
        do
        line=`echo "${atmfile[$id]}" | grep -n "$ref" | cut -d : -f 1`
        [ 0${line//[^0-9]} -gt 0 ] && displayclientname $id ${line//[^0-9]} && break
        let $[id++]
    done
    
    shift
done

exit 0
