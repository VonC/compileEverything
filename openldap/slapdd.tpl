#! /bin/bash

SLAPD="${H}/openldap/slapd -s0"
CONF1="${H}/openldap/slapd.1.conf"
LVL=0x4105
URI1="ldap://localhost:@PORT_LDAP_TEST@/ ldap://@FQN@:@PORT_LDAP_TEST@/"
LOG1="${H}/openldap/slapd.1.log"
PIDFILE="${H}/openldap/slapd.1.pid"
ARGSFILE="${H}/openldap/slapd.1.args"

PORT1=@PORT_LDAP_TEST@
LOCALHOST=localhost
TOOLARGS="-x $LDAP_TOOLARGS"
TOOLPROTO="-P 3"
LDAPSEARCH="ldapsearch $TOOLPROTO $TOOLARGS -LLL"


auser=$(id -nu)
aps=$(ps -ef|grep ${auser}|grep "${H}/openldap/slapd"|grep -v grep|awk '{print $2}')
afps=""
if [[ -e "${PIDFILE}" ]] ; then 
  afps=$(cat "${PIDFILE}")
fi

if [[ ! -e "${H}/openldap/db.1.a" ]] ; then mkdir -p "${H}/openldap/db.1.a" ; fi

# echo "aps ${aps}, afps ${afps}"

case "$1" in

'start')
  if [[ "$aps" == "" ]] ; then
    echo starting slapd
    $SLAPD -f $CONF1 -h "$URI1" -d $LVL $TIMING &> "${LOG1}" &
  else
    echo "slapd already started, process ${aps}"
  fi
  ;;
'stop')
  if [[ "$aps" != "" ]] ; then
    echo stopping slapd
    kill -9 "${aps}"
  else
    echo "slapd already stopped"
  fi
  if [ -e "${PIDFILE}" ] ; then rm -f "${PIDFILE}" ; fi
  if [ -e "${ARGSFILE}" ] ; then rm -f "${ARGSFILE}" ; fi
  ;;
'restart')
  slapdd stop
  slapdd start
;;
'status')
  if [[ "${aps}" == "" ]] ; then
    echo "slapd is stopped"
  else
    echo "slapd running, process ${aps}"
    #ldapsearch -x -s base -b "cn=monitor" -h localhost -p @PORT_LDAP_TEST@ 'objectclass=*'
    echo $LDAPSEARCH -b "cn=monitor" -s base -h $LOCALHOST -p $PORT1 'objectclass=*'
    $LDAPSEARCH -b "cn=monitor" -s base -h $LOCALHOST -p $PORT1 'objectclass=*'
  fi
  if [[ "${afps}" != "${aps}" ]] ; then
    echo "Warning, the slapd pid recorded is not the same: ${afps}"
  fi
  ;;
*)
  echo "usage: ${H}/sbin/slapdd {start|stop|restart|status}"
  ;;
esac

