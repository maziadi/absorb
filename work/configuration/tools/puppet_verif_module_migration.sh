#!/bin/sh

liste=$(cat modules/$1/manifests/*.pp | grep -o "class ${1}::[-a-zA-Z0-9_]*" | cut -c $(expr 8 + $(echo -n "${1}" | wc -c) + 1)-)

for classname in $liste
do
  grepf "class([^[[:space:]]*[[:space:]])*[\'\"]*${classname}[\'\"]*([^-a-zA-Z0-9:]+|$)"
  grepf "include([^[[:space:],]*[[:space:],])*[\'\"]*${classname}[\'\"]*([^-A-Za-z0-9:]+|$)"
  grepf "Class\[[\'\"]*${classname}[\'\"]*\]"
done

liste=$(cat modules/$1/manifests/*.pp | grep -o "define [-a-zA-Z0-9_]*" | cut -c 8-)

for definename in $liste
do
  grepf "${definename}[[:space:]]*{" | grep -v "${1}::.*${definename}[[:space:]]*{"
done


