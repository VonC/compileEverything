#!/home/auser/compileEverything/usr/local/apps/perl/bin/perl
our $s=system("/home/auser/compileEverything/cgit/cgit.cgi");
our @lines=split($s);
pop(@lines);
foreach (@lines) {
  print $_;
} 
