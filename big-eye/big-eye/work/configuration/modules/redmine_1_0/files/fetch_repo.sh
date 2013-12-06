#!/bin/sh
base='/var/cache/redmine/default/git/'
for repo in erp.git taxman.git supervision.git apnf.git lima.git l2tp.git waitaddr.git; do
  cd $base$repo
  git fetch -q --all
done
