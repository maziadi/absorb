#!/bin/sh

usage () {
  echo "$0 -v <version> -h <hostname> -t <type> [-n]"
  echo "   -h <hostname> : deploy on <hostname>"
  echo "   -v <version> : version to deploy"
  echo "   -t <type> : deploy version for <type>"
  echo "   -r : reinitialize environment (WARNING: karaf restarting)"
  echo "   -n : dry run"
  exit -1
}

while getopts :h:t:v:rn opt
do
  case $opt in
    h) HOST=$OPTARG;;
    t) TYPE=$OPTARG;;
    v) VERSION=$OPTARG;;
    r) REINIT=1;;
    n) EXTRAOPT="-n";;
    [?]) usage;;
  esac
done

shopt -s extglob

if [ -z "$HOST" ]
  then
  echo "Hostname is required !"
  usage
  exit -1
elif [ -z "$VERSION" ]
  then
  echo "Version is required !"
  usage
  exit -1
elif [ -n "${TYPE#@(as|agent)}" ]
  then
  echo "One type needed (as or agent) !"
  usage
  exit -1
fi

OPTS="-aczvp --no-o --no-g --delete ${EXTRAOPT}"

rsync $OPTS svn:sigal-${VERSION}-SNAPSHOT /tmp/sigal

case $TYPE in
  as)
    EXCLUDES="--exclude=agent-${VERSION}-SNAPSHOT.jar --exclude=hss-${VERSION}-SNAPSHOT.jar"
    rsync $OPTS $EXCLUDES /tmp/sigal/sigal-${VERSION}-SNAPSHOT/lib/ $HOST:/var/lib/karaf/deploy/
    ;;
  agent)
    EXCLUDES="--exclude=as-${VERSION}-SNAPSHOT.jar --exclude=hss-${VERSION}-SNAPSHOT.jar"
    rsync $OPTS $EXCLUDES /tmp/sigal/sigal-${VERSION}-SNAPSHOT/lib/ $HOST:/var/lib/karaf/deploy/
    ;;
esac

if [ "$EXTRAOPT" = '-n' -a "$REINIT" ]
  then
  echo "ssh $HOST '/etc/init.d/karaf stop; rm -r /var/lib/karaf/data/*; chown -Rc karaf:adm /var/lib/karaf/deploy; /etc/init.d/karaf start'"
elif [ $REINIT ]
  then
  ssh $HOST '/etc/init.d/karaf stop; rm -r /var/lib/karaf/data/*; chown -Rc karaf:adm /var/lib/karaf/deploy; /etc/init.d/karaf start'
fi
