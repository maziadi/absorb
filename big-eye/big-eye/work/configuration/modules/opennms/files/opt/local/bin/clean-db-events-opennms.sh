#!/bin/bash

if [ -z "$1" ]; then
  echo ""
  echo "This script clean old events in OpenNMS database"
  echo "Usage: $0 <database username>"
  exit 1
fi 

REINDEX=/usr/bin/reindexdb
VACUUM=/usr/bin/vacuumdb
PSQL=/usr/bin/psql
USER=$1
DB=opennms

echo "DELETE FROM events WHERE eventtime <= current_date -
interval '6 months';" | $PSQL -U $USER $DB
$VACUUM -afvz -U $USER
$REINDEX -a -U $USER

