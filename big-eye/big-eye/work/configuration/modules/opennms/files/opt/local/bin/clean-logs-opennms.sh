#!/bin/bash

OLDPATH=`pwd`
cd /var/log/opennms/daemon

list=`ls /var/log/opennms/daemon`
for file in $list
do
  if [ "$file" == "clean.sh" ]; then continue 
  fi
  cat /dev/null > $file
done

cd $OLDPATH

OLDPATH=`pwd`
cd /var/log/opennms/webapp

list=`ls /var/log/opennms/webapp`
for file in $list
do
  if [ "$file" == "clean.sh" ]; then continue 
  fi
  cat /dev/null > $file
done

cd $OLDPATH

