#!/bin/bash

if [ -f ~/.ssh/config ];
then
  cp ~/.ssh/config ~/.ssh/config.bak
  ed ~/.ssh/config 2>&1 > /dev/null <<EOF
\$
?## Config Alphalink ##?
.,\$d
w
q
EOF
  if [ $? != 0 ]
  then
      echo "Impossible de supprimer les entrees precedentes..."
      echo " (ce message est normal en cas de premiere execution)" 
  fi
fi

cat dist/ssh_config >> ~/.ssh/config
if [ $? != 0 ]
then
    echo "Impossible de concatener les entrees communes a la fin du fichier"
    exit -1
fi
