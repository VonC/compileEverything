#!/usr/bin/env perl
use lib 'lib';
use strict;
use warnings;
#use Log;
use Git;	
my $version = Git::command_oneline('version');
printf "$version\n";

# http://stackoverflow.com/questions/3854651/how-can-i-store-the-result-of-a-system-command-in-a-perl-variable
my $demod=`demod status 2>&1`;
my $h=$ENV{H};

#printf "$demod";
my $status = 0;
if ($demod =~ /lynx: Can't access startfile/) {
  # http://stackoverflow.com/questions/619393/how-do-i-write-text-in-aligned-columns-in-perl
  printf "%-15s : %-15s\n", "Apache", "OFFLINE";
  $status = 1;
} else {
  printf "%-15s : %-15s\n", "Apache","online";
}
if ($demod =~ /sshd running/) {
  printf "%-15s : %-15s\n", "sshd", "online";
} else {
  printf "%-15s : %-15s\n", "sshd", "OFFLINE";
  $status = 1;
}
if ($demod =~ /slapd running/) {
  printf "%-15s : %-15s\n", "LDAP", "online";
} else {
  printf "%-15s : %-15s\n", "LDAP", "OFFLINE";
  $status = 1;
}
if ($demod =~ /nginx running/) {
  printf "%-15s : %-15s\n", "NGiNX", "online";
} else {
  printf "%-15s : %-15s\n", "NGiNX", "OFFLINE";
  $status = 1;
}
if ($demod =~ /Next mcron job is/) {
  printf "%-15s : %-15s\n", "mcrond", "online";
} elsif (-e "$h/mcron/mcron") {
  printf "%-15s : %-15s\n", "mcrond", "OFFLINE";
  $status = 1;
} else {
   printf "%-15s : %-15s\n", "mcrond", "N/A (not staging)";
}

my $gitdir = "$h/repositories/gitolite-admin.git";
my $repo = Git->repository (Directory => $gitdir);
my @remotes = $repo->command('remote', '-v');
foreach(@remotes) {
  my $remoteline = $_;
  my ($remote, $value) = split /\s+/, $remoteline, 2;
  if ($value =~ /\(fetch\)/) { next; }
  printf "remote: $remote, for remoteline '$remoteline'";
  my @revs = $repo->command('ls-remote', $remote);
  # printf scalar @revs;
  foreach(@revs)
  {
    my $rev = $_;
    # printf "[$remote]: $rev\n";
  }
  printf ": OK\n"
}
exit $status;
