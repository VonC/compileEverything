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

open( my $repofile, "<", "$h/git/test.repo.private" ) || die "Can't open $h/git/test.repo.private: $!";
my $reponame = join('', <$repofile>);
$reponame =~ s/\s+$//;
print "repo:${reponame}\n";
open( my $branchfile, "<", "$h/git/test.branch.private" ) || die "Can't open $h/git/test.branch.private: $!";
my $branchname = join('', <$branchfile>);
$branchname =~ s/\s+$//;
print "branch:$branchname\n";

my $repopath = "$h/repositories/${reponame}.git";
print "repopath=$repopath\n";
my $repo = Git->repository (Directory => $repopath);

my $ref = $repo->command('rev-parse', 'HEAD@{1}');
$ref =~ s/\s+$//;
print "ref=$ref\n";

# goto END;

chdir $repopath;
system("git --git-dir=$repopath branch --force master $ref");
system("$repopath/hooks/post-update master");

sleep (30);
END:
my $refbranch = $repo->command('rev-parse', "$branchname");
$refbranch =~ s/\s+$//;
print "ref=$refbranch\n";

if ($ref eq $refbranch) {
  print "OK: roundtrip done\n";
  exit 0;
}
print "KO: roundtrip failed!\n";
exit 1;
