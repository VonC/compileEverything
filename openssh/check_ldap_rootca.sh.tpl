#!/bin/sh

if [[ -e "${H}/.ldap.private" ]] ; then f="${H}/.ldap.private"  ; 
elif [[ -e "${H}/../.ldap.private" ]] ; then f="${H}/../.ldap.private" ; 
else exit 0
fi
echo "f='${f}'"

CAs="${H}/.ssh/curl-ca-bundle.crt"
ossh="${H}/openssh"
ldapserver=@LDAP_HOSTNAME@:@LDAP_PORT@
e=$(openssl s_client -connect ${ldapserver} -CAfile "${CAs}" 2>/dev/null < /dev/null | grep "unable to get local issuer certificate")
if [[ "${e}" != "" ]] ; then
  echo "get root CA for ${ldapserver}"
  echo -n | openssl s_client -showcerts -connect ${ldapserver} 2>/dev/null  | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'| gawk '/BEGIN/{s=""} {s=s $0 RS} END{printf("%s",s)}' > "${ossh}/ldapserver.pem"
  i=$(grep -f "${ossh}/ldapserver.pem" "${CAs}" | grep -v CERTIFICATE)
  if [[ "${i}" == "" ]] ; then cat "${ossh}/ldapserver.pem" >> "${CAs}" ; fi
  e=$(openssl s_client -connect ${ldapserver} -CAfile "${CAs}" 2>/dev/null < /dev/null | grep "unable to get local issuer certificate")
  if [[ "${e}" != "" ]] ; then
    crt=$(openssl x509 -in "${ossh}/ldapserver.pem" -noout -text| grep "CA Issuers" | grep http | head -1 | gawk '{ print $4 }')
    crt="${crt#*:}"
    #echo "D: crt='${crt}'"
    wget "${crt}" -O "${ossh}/ldapRootCA.crt"
    openssl x509 -inform der -in "${ossh}/ldapRootCA.crt" -out "${ossh}/ldapRootCA.pem"
    i=$(grep -f "${ossh}/ldapRootCA.pem" "${CAs}" | grep -v CERTIFICATE)
    if [[ "${i}" == "" ]] ; then cat "${ossh}/ldapRootCA.pem" >> "${CAs}" ; fi
    e=$(openssl s_client -connect ${ldapserver} -CAfile "${CAs}" 2>/dev/null < /dev/null | grep "unable to get local issuer certificate")
    if [[ "${e}" != "" ]] ; then
      echo  -e "\e[1;31mNo valid Root CA for ${ldapserver}\e[0m" 1>&2
      echo "e='${e}'"
      exit 1
    else
      echo "ok"
    fi  
  fi
fi
