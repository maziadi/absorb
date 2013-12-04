#!/bin/bash

liste=$(tools/grepf '^[[:space:]]*node .*{' | cut -d : -f 3 | awk '{print $2}' | sed "s/['{]//g")

echo "Node;infra;ssh"

for node in $liste
do
  tools/infra.rb search $node -c | grep -q $node
  infra=$(($?^1))
  ssh -oStrictHostKeyChecking=false $node echo 2>/dev/null
  ssh=$(($(($?^255))&1))
  echo "${node};${infra};${ssh};"
done
