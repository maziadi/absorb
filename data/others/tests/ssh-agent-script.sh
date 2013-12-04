#!/bin/bash

PIDS="$(pgrep -u `id -u` ssh-agent)"
for PID in $PIDS ;
do
  let "PARENT_PID=$PID-1"
  if [ -S /tmp/ssh-*/agent.$PARENT_PID ]
  then
    echo " found"
    export SSH_AGENT_PID=$PID
    export SSH_AUTH_SOCK=$(find /tmp/ssh-*/ -type s -name agent.$PARENT_PID)
    echo $SSH_AUTH_SOCK
  fi
done

