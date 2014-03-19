#!/bin/sh

source "${H}/sbin/usrcmd/get_hostname"

get_hostname a_hostname

priv="${H}/../.cert.private"
crt="${H}/../${a_hostname}.crt"
if [[ ! -e "${priv}" ]] ; then exit 0 ; fi 
if [[ ! -e "${crt}" ]] ; then exit 0 ; fi

jks=$(grep jks "${priv}")
jks=${jks##*=}
#echo "jks='${jks}'"
if [[ "${jks}" == "" ]] ; then echo "missing JKS keystore at '${jks}'" ; exit 1 ; fi

jkspwd=$(grep password "${priv}")
jkspwd=${jkspwd##*=}
#echo "jkspwd='${jkspwd}'"

jksalias=$(grep alias "${priv}")
jksalias=${jksalias##*=}
#echo "jkspwd='${jkspwd}'"

# http://stackoverflow.com/a/5596842/6309
# Extract private key from keystore

p12="${H}/../${a_hostname}.p12"

if [[ ! -e "${p12}" ]] ; then
  keytool -importkeystore -srckeystore "${jks}" -srcstoretype jks -srcstorepass "${jkspwd}" -destkeystore "${p12}" -deststoretype pkcs12 -deststorepass "${jkspwd}" -alias "${jksalias}" 
fi

key="${H}/../${a_hostname}.key"

if [[ ! -e "${key}" ]] ; then
  openssl pkcs12 -in "${p12}" -out "${key}" -nodes -passin pass:${jkspwd}
fi
if [[ ! -e "${H}/openssh/${a_hostname}.key" && -e "${key}" ]] ; then
  cat "${key}" >> "${H}/.ssh/curl-ca-bundle.crt"
  cp "${key}" "${H}/openssh"
fi
