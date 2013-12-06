#!/bin/sh

if [ -z "$1" ];
then
  echo "Usage: $0 <ssh url> <name_repo>"
  exit -1
fi
url=$1
repo=$2

ssh root@$url \
reprepro -b /data/packages/debian processincoming $repo || (
        echo "Impossible de publier le paquetage!"
        exit -1
        ) || exit
