#!/bin/bash

OPTS="-azv"
EXTRAOPTS=""

#Usage
function usage() {
  echo "Usage: $0 <path to refresh> [-n]"
  echo "  -n : dry run"
  exit 1
}

if [ $# -lt 1 -o $# -gt 2 ] || [ $# = 2 -a "$2" != '-n' ]
then
  usage
fi

if [ $# = 2 ] # NoOp
then
  OPTS="${OPTS}n"
fi

path=$1
noop=$2 #For DRY RUN : rsync -n


if [ -f "$path" ] #Test if $path is a  File
then
  true
elif [ -d "$path" ] #Test if $path is a Directory
then
  EXTRAOPTS="--existing --delete --exclude=.svn"
  path=$(echo $path | sed 's#[^/]$#&/#')
  if [ -z "$(echo $path | sed 's|dist/nodes/[^/]*/*||')" ]
  then
    EXTRAOPTS="${EXTRAOPTS} --exclude=/proc"
  fi

else # Otherwise
  echo "'${path}' must exist"
  exit 1
fi

remote=$(echo "$path" | sed 's|dist/nodes/\([^/]*\)\(.*\)|\1:\2|')
rsync $OPTS $EXTRAOPTS "${remote}" "${path}"

exit 0
