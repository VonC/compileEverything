#!/bin/bash
export H="@H@"
export D=3
if [[ "${REMOTE_USER}" =~ ^[0-9]+$ ]] ; then
  echo "Potential HSBC user, checking group..." >> a
  lport="@LDAP_PORT@"
  if [[ "${lport#@}" == "${lport}" && ! -e "${REMOTE_USER}" ]] ; then
    l=$(ldapsearch -H ldaps://@LDAP_HOSTNAME@:@LDAP_PORT@ -x -D "@LDAP_BINDDN@" -w @LDAP_PASSWORD@ -b "@LDAP_BASE@" -s sub -a always -z 1000 "(cn~=${REMOTE_USER})" "memberof" | grep -i "memberof")
    echo "LDAP='${l}'" >> a
    if [[ "${l#*CN=}" != "${l}" ]] ; then
      names=""
      while read -r line; do
        if [[ "${line#*CN=}" != "${line}" ]] ; then
          aname="${line#*CN=}"
          aname="${aname%%,*}"
          if [[ "${names}" != "" ]] ; then names="${names}," ; fi
          names="${names}${aname}"
        fi
      done <<< "${l}"
      echo "${names}" >> "${REMOTE_USER}"
    fi
  fi
fi
if [[ -e "${REMOTE_USER}" ]]; then
  export REMOTE_USER_GROUPS="$(cat ${REMOTE_USER})"
fi
echo "REMOTE_USER_GROUPS='${REMOTE_USER_GROUPS}' for user '${REMOTE_USER}'" >> a
"${H}/gitolite/bin/gitolite-shell"
unset REMOTE_USER_GROUPS
