#
#Creating a self-signed certificate
#

####################################################################
[req]
days                   = 720
serial                 = 1
distinguished_name     = req_distinguished_name
x509_extensions        = v3_ca
prompt                 = no

[req_distinguished_name]
countryName            = FR
stateOrProvinceName    = France
localityName           = Paris
organizationName       = company
organizationalUnitName = department
commonName             = @FQN@
emailAddress           = @EMAIL@


[ v3_ca ]
subjectAltName         = DNS:@FQN@, DNS:@HOSTNAME@
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
basicConstraints       = CA:TRUE
keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement, keyCertSign
issuerAltName          = issuer:copy
