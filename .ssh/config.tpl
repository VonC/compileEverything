Host *
  UserKnownHostsFile @H@/.ssh/known_hosts

Host gitolitesrv
  Hostname localhost
  User vobadm
  Port @PORT_SSHD@
  IdentityFile @H@/.ssh/gitoliteadm

Host gitolitesrv_root
  Hostname localhost
  User vobadm
  Port @PORT_SSHD@
  IdentityFile @H@/.ssh/root
