#! /bin/bash

apache="${H}/apache"
if [[ -e "${apache}/key" && -e "${apache}/crt" ]] ; then exit 0 ; fi

hkey="${H}/../$(hostname).key"
hcrt="${H}/../$(hostname).crt"

if [[ -e "${hkey}" && -e "${hcrt}" ]] ; then
  ln -fs "${hkey}" "${apache}/key"
  ln -fs "${hcrt}" "${apache}/crt"
  exit 0
fi

# if no private certificate was given, generate self-signed one locally

fqn=$(host -TtA $(hostname -s)|grep "has address"|awk '{print $1}') ; if [[ "${fqn}" == "" ]] ; then fqn=$(hostname -s) ; fi
fqnpassword="${fqn}1";
passphrasekey="${apache}/${fqn}.passphrase.key"
key="${apache}/${fqn}.key"
cert="${apache}/${fqn}.crt"
cnf="${apache}/o.cnf"
#cnf="${apache}/openssl.cnf"
ext="v3_ca"
#ext="v3_req"
if [[ ! -e "${passphrasekey}" ]]; then
  openssl genrsa -des3 -passout pass:${fqnpassword} -out "${passphrasekey}" 1024
  openssl rsa -passin pass:${fqnpassword} -in "${passphrasekey}" -out "${key}"
  openssl req -new -config "${cnf}" -extensions "${ext}" -x509 -days 730 -key "${key}" -out "${cert}"
  cat "${cert}" >> "${H}/.ssh/curl-ca-bundle.crt"
fi
ln -fs "${fqn}.key" "${apache}/key"
ln -fs "${fqn}.crt" "${apache}/crt"

