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


ln -fs ../../../.ssh/cnf "${H}/usr/local/etc/sshd_config"
cp_tpl "${H}/.ssh/cnf.tpl" "${H}/.ssh"
mkdir -p "${H}/usr/local/var/run"
cp_tpl "${H}/.ssh/config.tpl" "${H}/.ssh" 
ln -fs ../../../.ssh/config "${H}/usr/local/etc/ssh_config" 
chmod 700 "${H}/.ssh"
if [[ ! -h "${HULS}/openssh/etc/sshd_config" ]] ; then 
  cp -f "${HULS}/openssh/etc/sshd_config" "${HULS}/openssh/etc/sshd_config.ori"
  ln -fs ../../../../../.ssh/cnf "${HULS}/openssh/etc/sshd_config"
fi
if [[ ! -h "${HULS}/openssh/etc/sshd_config" ]] ; then
  cp -f "${HULS}/openssh/etc/ssh_config" "${HULS}/openssh/etc/ssh_config.ori"
  ln -fs ../../../../../.ssh/config "${HULS}/openssh/etc/ssh_config"
fi
if [[ ! -e "${H}/.ssh/root" ]]; then 
  ssh-keygen -t rsa -f "${H}/.ssh/root" -C "Local root access (interactive)" -q -P "" ; cat "${H}/.ssh/root.pub" >> "${H}/.ssh/authorized_keys"
fi

if [[ ! -e "${H}/.ssh/known_hosts" ]] ; then
  touch "${H}/.ssh/known_hosts"
  chmod 644 "${H}/.ssh/known_hosts"
fi
k=$(ssh-keyscan -t rsa,dsa $(hostname) 2>&1 | sort -u - ~/.ssh/known_hosts)
echo "k=$k"

l=$(grep $(hostname) "${H}/.ssh/known_hosts")
if [[ "${k}" != "" && "${k}" != "${l}" ]] ; then
  echo "${k}" >> "${H}/.ssh/known_hosts"
fi
