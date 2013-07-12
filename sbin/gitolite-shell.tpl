#!/bin/bash
export H="@H@"
if [ -z "${REQUEST_URI}" ]; then
  "${H}/gitolite/bin/gitolite-shell"
  res=$?
  echo "bog res='${res}'" > a
else
  a=$(grep "${REMOTE_USER}" "${H}/.ssh/authorized_keys")
  #echo "${REMOTE_USER}: ${a}" > aaa
  if [ ! -z "${a}" ] ; then
    a="${a%%\",*}"
    a="${a##* }"
    #echo "new a: ${a}" >> aaa
    if [ ! -z ${a} ] ; then
      export REMOTE_USER="${a}"
    fi
  fi
  "${H}/gitolite/bin/gitolite-shell"
  res=$?
  echo "res='${res}'" > a
  if [[ "${res}" == "0" ]] ; then exit 0 ; fi
  if ! [[ "${REMOTE_USER}" =~ ^[0-9]+$ ]] ; then exit ${res} ; fi
  res=1
  echo "Potential HSBC user, checking group..." >> a
  lport="@LDAP_PORT@"
  if [[ "${lport#@}" != "${lport}" ]] ; then exit ${res} ; fi
  l=$(ldapsearch -H ldaps://@LDAP_HOSTNAME@:@LDAP_PORT@ -x -D "@LDAP_BINDDN@" -w @LDAP_PASSWORD@ -b "@LDAP_BASE@" -s sub -a always -z 1000 "(cn~=${REMOTE_USER})" "memberof")
  echo "LDAP='${l}'" >> a
  exit ${res}
fi
