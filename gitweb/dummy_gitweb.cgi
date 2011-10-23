#!/home/auser/compileEverything/usr/local/apps/perl/bin/perl

use 5.008;
use strict;
use warnings;

use CGI qw(:standard :escapeHTML -nosticky);
use CGI::Util qw(unescape);
use CGI::Carp qw(fatalsToBrowser set_message);
use Encode;
use Fcntl ':mode';
use File::Find qw();
use File::Basename qw(basename);
use Time::HiRes qw(gettimeofday tv_interval);
binmode STDOUT, ':utf8';

our $t0 = [ gettimeofday() ];
our $number_of_git_cmds = 0;

BEGIN {
	CGI->compile() if $ENV{'MOD_PERL'};
}

print "Content-type: text/plain\n\n";
print "Hello GitWeb!\n";

our $CGI = 'CGI';
our $cgi = $CGI->new();
our $my_url = $cgi->url();


print "cgi: $cgi\n";

print "Remote user: $ENV{REMOTE_USER}";

our $key;
foreach $key (sort(keys %ENV)) {
    print "$key = $ENV{$key}\n";
}
