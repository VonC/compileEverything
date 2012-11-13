#!/bin/sh

priv="${H}/../.cert.private"
crt="${H}/../$(hostname).crt"
if [[ ! -e "${priv}" ]] ; then exit 0 ; fi 
if [[ ! -e "${crt}" ]] ; then exit 0 ; fi

jks=$(grep jks "${priv}")
jks=${jks##*=}
#echo "jks='${jks}'"
if [[ ! -e "${jks}" ]] ; then echo "missing JKS keystore at '${jks}'" ; exist 1 ; fi

jkspwd=$(grep password "${priv}")
jkspwd=${jkspwd##*=}
#echo "jkspwd='${jkspwd}'"

jksalias=$(grep alias "${priv}")
jksalias=${jksalias##*=}
#echo "jkspwd='${jkspwd}'"

p12="${H}/../$(hostname).p12"

if [[ ! -e "${p12}" ]] ; then
  keytool -importkeystore -srckeystore "${jks}" -srcstoretype jks -srcstorepass "${jkspwd}" -destkeystore "${p12}" -deststoretype pkcs12 -deststorepass "${jkspwd}" -alias "${jksalias}" 
fi

key="${H}/../$(hostname).key"

if [[ ! -e "${key}" ]] ; then
  openssl pkcs12 -in "${p12}" -out "${key}" -nodes -passin pass:${jkspwd}
  cat "${key}" >> "${H}/.ssh/curl-ca-bundle.crt"
fi
