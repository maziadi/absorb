#!/bin/bash


if [ -z "$1" ];
then
    echo "Usage: $0 <server url> [key file]"
    exit -1
fi

SRV=$1
FILE=${HOME}/.ssh/id_dsa.pub

if [ ! -z "$2" ];
then
    FILE=$2
fi

cat ${FILE} | ssh ${SRV} "mkdir -p .ssh; chmod 700 .ssh; cat >> .ssh/authorized_keys; chmod 600 .ssh/authorized_keys"
