#!/bin/bash
iozone="/usr/bin/iozone"
memory=$(ruby -e "puts $(cat /proc/meminfo | grep MemTotal | awk '{print $2}')/1024")
name=$(echo $HOSTNAME-$(date "+%Y%m%d-%H-%M").txt)
echo "Lauch iozone test on $HOSTNAME"
date
time $iozone -Raz -g ${memory}M > $name
date
