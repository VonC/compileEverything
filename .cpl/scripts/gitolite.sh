#!/bin/bash

mkdir -p "${H}/.ssh"
chmod 700 "${H}/.ssh"
if [[ ! -e "${H}/.ssh/authorized_keys" ]] then
  touch "${H}/.ssh/authorized_keys"
fi
chmod 600 "${H}/.ssh/authorized_keys"
if [[ ! -e "${H}/.ssh/curl-ca-bundle.crt" ]] then
  cp "${H}/.cpl/scripts/curl-ca-bundle.crt" "${H}/.ssh/curl-ca-bundle.crt"
fi
