#!/home/auser/compileEverything/usr/local/apps/perl/bin/perl
#print "Content-type: text/html\n\n";
our $s=system("/home/auser/compileEverything/cgit/cgit.cgi");
#print "Hello Cgit!\n";
print "$s";
