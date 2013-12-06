#!/bin/sh
# exemple : sh -x repli_mysql.sh -m log-1-maquette -s log-2-maquette -u rep_slave -p Eipha8si -b SYSLOG -r Ikta2429
USAGE () {
  echo "use this script to setup a mysql slave"
  echo "usage : $0 -m MASTER -s SLAVE -b BASE -u REP_USER -p REP_USER_PASS -r DATABASE_ROOT_PASSWORD"
}

while getopts :b:m:p:r:s:u: opt
do
  case $opt in
    b) BASE=${OPTARG}
    ;;
    m) MASTER=${OPTARG}
    ;;
    p) USER_PASS=${OPTARG}
    ;;
    r) ROOT_PASS=${OPTARG}
    ;;
    s) SLAVE=${OPTARG}
    ;;
    u) USER=${OPTARG}
    ;;
    '?') echo "${0} : option ${OPTARG} is not valid" >&2
         USAGE
         exit -1
    ;;
  esac
done


ACCESS="mysql -u root -p$ROOT_PASS"
STATUS="use $BASE; FLUSH TABLES WITH READ LOCK;SHOW MASTER STATUS;"
FILE=$(ssh $MASTER "$ACCESS -e \"$STATUS\""| grep -v File | awk '{print $1}')
POSI=$(ssh $MASTER "$ACCESS -e \"$STATUS\""| grep -v File | awk '{print $2}')
SLAVE_START="CHANGE MASTER TO MASTER_HOST=\\\"$MASTER\\\", MASTER_USER=\\\"$USER\\\", MASTER_PASSWORD=\\\"$USER_PASS\\\", MASTER_LOG_FILE=\\\"$FILE\\\", MASTER_LOG_POS=$POSI;"

LOCK () {
  ssh $MASTER "$ACCESS -e \"use $BASE; FLUSH TABLES WITH READ LOCK;\"" 
}

UNLOCK () {
  ssh $MASTER "$ACCESS -e \"use $BASE; UNLOCK TABLES;\""
}

DUMP () {
  ssh $MASTER "mysqldump -u root -p$ROOT_PASS SYSLOG" > /tmp/${BASE}.sql
}

ADD_DUMP () {
  scp /tmp/${BASE}.sql $SLAVE:/tmp
  ssh $SLAVE "$ACCESS $BASE < /tmp/${BASE}.sql"
#  rm /tmp/${BASE}.sql
}
ADD_SLAVE () {
  ssh $SLAVE "$ACCESS -e \"SLAVE STOP;\""
  ssh $SLAVE "$ACCESS -e \"$SLAVE_START\""
  ssh $SLAVE "$ACCESS -e \"SLAVE START;\""
}

LOCK
DUMP
UNLOCK
ADD_DUMP
ADD_SLAVE


