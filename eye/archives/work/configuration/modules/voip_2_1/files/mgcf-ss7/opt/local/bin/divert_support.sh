#!/bin/bash

if [ -z "$1" -o "YES" != "$1" ];
then
  VALUE=NO
else
  VALUE=YES
fi
echo "Setting diversion to ${VALUE}"

asterisk -r -x "core set global DIVERT_SUPPORT ${VALUE}"
