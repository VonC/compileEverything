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
  $status = $status | 1;
} else {
  printf "%-15s : %-15s\n", "Apache","online";
}
if ($demod =~ /sshd running/) {
  printf "%-15s : %-15s\n", "sshd", "online";
} else {
  printf "%-15s : %-15s\n", "sshd", "OFFLINE";
  $status = $status | 2;
}
if ($demod =~ /slapd running/) {
  printf "%-15s : %-15s\n", "LDAP", "online";
} else {
  printf "%-15s : %-15s\n", "LDAP", "OFFLINE";
  $status = $status | 4;
}
if ($demod =~ /nginx running/) {
  printf "%-15s : %-15s\n", "NGiNX", "online";
} else {
  printf "%-15s : %-15s\n", "NGiNX", "OFFLINE";
  $status = $status | 8;
}
if ($demod =~ /Next mcron job is/) {
  printf "%-15s : %-15s\n", "mcrond", "online";
} elsif (-e "$h/mcron/mcron") {
  printf "%-15s : %-15s\n", "mcrond", "OFFLINE";
  $status = $status | 16;
} else {
   printf "%-15s : %-15s\n", "mcrond", "N/A (not staging)";
}

my $gitdir = "$h/repositories/gitolite-admin.git";
my $repo = Git->repository (Directory => $gitdir);
my @remotes = $repo->command('remote', '-v');
@remotes = reverse @remotes;
my $st = 32;
foreach(@remotes) {
  my $remoteline = $_;
  my ($remote, $value) = split /\s+/, $remoteline, 2;
  if ($value =~ /\(fetch\)/) { next; }
  printf "%-15s ", "remote $remote";
  # http://stackoverflow.com/questions/109124/how-do-you-capture-stderr-stdout-and-the-exit-code-all-at-once-in-perl
  my $ast = system "git --git-dir=$gitdir ls-remote $remote 1>$h/git/test.log 2>&1 ";
  if ($ast != 0) {
    printf ": KO\n";
    $status = $status | $st
  } else {
    printf ": OK\n"
  }
  $st = $st * 2;
}
printf "------\nstatus: $status\n";
exit $status;
