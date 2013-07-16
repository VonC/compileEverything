#!/bin/bash
export H="@H@"
export D=3
aluser="${1}"
if [[ "${aluser}" == "" ]] ; then exit 0 ; fi
afuser="${H}/gitolite/ldap/${aluser}"
afuserl="${afuser}.log"
if [[ "${aluser}" =~ ^[0-9]+$  && ! -e "${afuser}" ]] ; then
  echo "Potential HSBC user, checking group..." >> "${afuserl}"
  lport="@LDAP_PORT@"
  if [[ "${lport#@}" == "${lport}" && ! -e "${afluser}" ]] ; then
    l=$(ldapsearch -H ldaps://@LDAP_HOSTNAME@:@LDAP_PORT@ -x -D "@LDAP_BINDDN@" -w @LDAP_PASSWORD@ -b "@LDAP_BASE@" -s sub -a always -z 1000 "(cn~=${aluser})" "memberof" | grep -i "memberof")
    echo "LDAP='${l}'" >> a
    if [[ "${l#*CN=}" != "${l}" ]] ; then
      names=""
      while read -r line; do
        if [[ "${line#*CN=}" != "${line}" ]] ; then
          aname="${line#*CN=}"
          aname="${aname%%,*}"
          aname="${aname// /_20_}"
          if [[ "${names}" != "" ]] ; then names="${names} " ; fi
          names="${names}${aname}"
        fi
      done <<< "${l}"
      echo "${names}" >> "${afuser}"
    fi
  fi
fi
if [[ -e "${afuser}" ]]; then
  echo "REMOTE_USER_GROUPS='$(cat ${afuser})' for user '${aluser}'" >> "${afuserl}"
  cat ${afuser}
fi
