#!/bin/bash

openldap="${H}/openldap"
if [[ ! -e "${openldap}/db.1.a/__db.001" ]] ; then
  slapdd start
  ldapmodify -a -P 3 -x -D "cn=Manager,dc=example,dc=com" -h localhost -p 9011 -w secret < "${openldap}/test-ordered.ldif"
  ldapmodify -a -P 3 -x -D "cn=manager,dc=example,dc=com" -h localhost -p 9011 -w secret < "${openldap}/gitoliteadm.ldif"
  slapdd stop
fi
