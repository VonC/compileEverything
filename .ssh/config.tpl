Host gitolitesrv
  Hostname localhost
  User @USERNAME@
  Port @PORT_SSHD@
  IdentityFile @H@/.ssh/gitoliteadm

Host gitolitesrv_root
  Hostname localhost
  User @USERNAME@
  Port @PORT_SSHD@
  IdentityFile @H@/.ssh/root

Host *
  UserKnownHostsFile @H@/.ssh/known_hosts
  Port @PORT_SSHD@
  IdentityFile @H@/.ssh/gitoliteadm
