#!/bin/sh

if [[ -e "${H}/.ldap.private" ]] ; then f="${H}/.ldap.private"  ; 
elif [[ -e "${H}/../.ldap.private" ]] ; then f="${H}/../.ldap.private" ; fi
echo "f='${f}'"

CAs="${H}/.ssh/curl-ca-bundle.crt"
e=$(openssl s_client -connect @LDAP_HOSTNAME@:@LDAP_PORT@ -CAfile "${CAs}" 2>/dev/null < /dev/null | grep "unable to get local issuer certificate")
if [[ "${e}" != "" ]] ; then
  echo "get root CA for"
  echo -n | openssl s_client -showcerts -connect @LDAP_HOSTNAME@:@LDAP_PORT@ 2>/dev/null  | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'| gawk '/BEGIN/{s=""} {s=s $0 RS} END{printf("%s",s)}' >> "${CAs}"
  e=$(openssl s_client -connect @LDAP_HOSTNAME@:@LDAP_PORT@ -CAfile "${CAs}" 2>/dev/null < /dev/null | grep "unable to get local issuer certificate")
  if [[ "${e}" != "" ]] ; then
    echo  -e "\e[1;31mNo valid Root CA for \e[0m" 1>&2
    echo "e='${e}'"
    exit 1
  fi
fi
