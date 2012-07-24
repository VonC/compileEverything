#!/bin/bash

mkdir -p "${H}/.ssh"
chmod 700 "${H}"
chmod 700 "${H}/.ssh"
if [[ ! -e "${H}/.ssh/authorized_keys" ]] ; then
  touch "${H}/.ssh/authorized_keys"
fi
chmod 600 "${H}/.ssh/authorized_keys"
if [[ ! -e "${H}/.ssh/curl-ca-bundle.crt" ]] ; then
  cp "${H}/.cpl/scripts/curl-ca-bundle.crt" "${H}/.ssh/curl-ca-bundle.crt"
fi

if [[ ! -e "${HULA}/openssh" ]] ; then
  aln=$(find "${HULA}" -maxdepth 1  -type d -name "openssh*")
  aln=${aln##*/}
  # echo "D: aln='${aln}'"
  ln -fs "${aln}" "${HULA}/openssh"
fi

ln -fs ../../../.ssh/cnf "${H}/usr/local/etc/sshd_config"
cp_tpl "${H}/.ssh/cnf.tpl" "${H}/.ssh"
mkdir -p "${H}/usr/local/var/run"
cp_tpl "${H}/.ssh/config.tpl" "${H}/.ssh" 
ln -fs ../../../.ssh/config "${H}/usr/local/etc/ssh_config" 
chmod 700 "${H}/.ssh"
if [[ ! -h "${HULA}/openssh/etc/sshd_config" ]] ; then 
  cp -f "${HULA}/openssh/etc/sshd_config" "${HULA}/openssh/etc/sshd_config.ori"
  ln -fs ../../../../../.ssh/cnf "${HULA}/openssh/etc/sshd_config"
fi
if [[ ! -h "${HULA}/openssh/etc/sshd_config" ]] ; then
  cp -f "${HULA}/openssh/etc/ssh_config" "${HULA}/openssh/etc/ssh_config.ori"
  ln -fs ../../../../../.ssh/config "${HULA}/openssh/etc/ssh_config"
fi
if [[ ! -e "${H}/.ssh/root" ]]; then 
  ssh-keygen -t rsa -f "${H}/.ssh/root" -C "Local root access (interactive)" -q -P "" ; cat "${H}/.ssh/root.pub" >> "${H}/.ssh/authorized_keys"
fi

if [[ ! -e "${H}/.ssh/known_hosts" ]] ; then
  touch "${H}/.ssh/known_hosts"
  chmod 644 "${H}/.ssh/known_hosts"
fi
k=$(ssh-keyscan -t rsa,dsa $(hostname) 2>&1 | sort -u)
# echo "k='${k}'"

l=$(grep $(hostname) "${H}/.ssh/known_hosts")
# echo "l='${l}'"
if [[ "${k}" != "" && "${k}" != "${l}" ]] ; then
  echo "${k}" >> "${H}/.ssh/known_hosts"
fi

sshd start
l=$(grep "localhost" "${H}/.ssh/known_hosts" | grep nist | tail -1)
p=$(grep "@PORT_SSHD@" "${H}/.ports.ini")
p=${p#*=}
k=$(ssh-keyscan -t ecdsa -p ${p} localhost 2>&1 | grep ecdsa | grep nist)
  echo "D: 0k='${k}'"
if [[ "${k}" != "" ]]; then
  k="[localhost]:${p} ${k#* }"
  # echo "D: 1k='${k}'"
  # echo "D: 0l='${l}'"
  if [[ "${k}" != "" && "${k}" != "${l}" ]] ; then
  # echo "${k}" >> "${H}/.ssh/known_hosts"
  fi
fi
