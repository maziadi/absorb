#!/bin/sh

[ $# -ne 3 ] && {
  echo "Usage : ${0} <start> <end> <on|off|status>"
  exit 1
}

START=$1
STOP=$2
STATUS=$3

for CHAN in  $(seq ${START} ${STOP})
do
  case $STATUS in
    status)
      asterisk -rnx "dahdi show channel ${CHAN}"  | grep DND | sed "s/DND/${CHAN}/"
      ;;
    on|off)
      asterisk -rnx "dahdi set dnd ${CHAN} ${STATUS}"
      ;;
    *)
      echo "Unknown option '${STATUS}'. Should be status, on or off."
      exit 1
  esac
done
