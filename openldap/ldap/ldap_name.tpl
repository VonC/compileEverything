#!/bin/bash
export H="@H@"
aluser="${1}"
if [[ "${aluser}" == "" ]] ; then exit 0 ; fi
afuser="${H}/openldap/ldap/${aluser}"
if [[ "${aluser}" =~ ^[0-9]+$  && ! -e "${afuser}" ]] ; then
  lport="3269"
  if [[ "${lport#@}" == "${lport}" && ! -e "${afluser}" ]] ; then
    l=$(ldapsearch -H ldaps://@LDAP_HOSTNAME@:@LDAP_PORT@ -x -D "@LDAP_BINDDN@" -w @LDAP_PASSWORD@ -b "@LDAP_BASE@" -s sub -a always -z 1000 "(cn~=${aluser})" "displayName" | grep -i "displayName:")
    echo "LDAP='${l}'" >> a
    if [[ "${l#*displayName:}" != "${l}" ]] ; then
      aname="${l#*displayName: }"
      echo "${aname} (${aluser})" >> "${afuser}"
    fi
  fi
fi
if [[ -e "${afuser}" ]]; then
  # http://askubuntu.com/a/121868/5470
  echo -n $(cat ${afuser})
else
  echo -n "${aluser}"
fi
