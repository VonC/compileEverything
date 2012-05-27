#! /bin/bash

fqn=$(host -TtA $(hostname -s)|grep "has address"|awk '{print $1}') ; if [[ "${fqn}" == "" ]] ; then fqn=$(hostname -s) ; fi
fqnpassword="${fqn}1";
apache="${H}/apache"
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

