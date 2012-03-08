#! /bin/bash

apache="${H}/apache"

ctld stop
last_line=$(tail -1 "${apache}/cnf1")
include="Include \"${apache}/cnf\""
if [[ "${last_line}" != "${include}" ]]; then
  echo add
  echo "${include}">>"${apache}/cnf1"
else
  echo ok
fi
gen_sed -i "s/^Listen 80/#Listen 80/" "${H}/apache/conf/httpd.conf"
