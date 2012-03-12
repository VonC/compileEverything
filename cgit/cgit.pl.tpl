#!@H@/usr/local/apps/perl/bin/perl
#print "<pre>\n";
use Time::localtime;
my $remote_user=$ENV{"REMOTE_USER"}; 
#print "REMOTE_USER = $remote_user<br />";
my $path_info=$ENV{"PATH_INFO"}; 
#print "PATH_INFO = $path_info<br />";
my $request_uri=$ENV{"REQUEST_URI"}; 
#print "REQUEST_URI = $request_uri<br />";
# foreach $key (sort keys(%ENV)) {
#   print "$key = $ENV{$key}<p>";
# }
#print "</pre>\n";

my $gl_home = $ENV{HOME} = "@H@";
$ENV{GL_RC} = "$gl_home/.gitolite.rc";
$ENV{GL_BINDIR} = "$gl_home/bin";
$ENV{GL_USER} = $remote_user;
# now get gitolite stuff in...
unshift @INC, $ENV{GL_BINDIR};
require gitolite_rc;    gitolite_rc -> import;
require gitolite;       gitolite    -> import;
# set project root etc. absolute paths
$ENV{GL_REPO_BASE_ABS} = ( $REPO_BASE =~ m(^/) ? $REPO_BASE : "$gl_home/$REPO_BASE" );
$projects_list = $projectroot = $ENV{GL_REPO_BASE_ABS};
#print "ok: projects_list $projects_list<br />";

if ($request_uri ne "/cgit/" && $request_uri ne "/cgit/cgit.pl/") {
  (my $repo)=($path_info =~ /\/([^\/]+)/);
  #print "ok: repo $repo<br />";
  my ($perm, $creator) = &repo_rights($repo);
  #print "ok: perm $perm<br />";
  #print "ok: creator $creator<br />";
  if ($perm =~ /R/) {
    system("@H@/cgit/cgit.cgi");
  }
  else {
    print "Content-type: text/html\n\n";
    print "<html>\n";
    print "<body>\n";
    print "	<h1>HTTP Status 403 - Access is denied</h1>\n";
    print "	<h3>You don't have access to repo $repo as $remote_user</h3>\n";
    print "</body>\n";
    print "</html>\n";
  }
}
else {
    my $fname="$remote_user.".timestamp().".tpl";
    system("@H@/cgit/cgit.cgi > $fname");
    open(INFO, $fname);		# Open the file
    @lines = <INFO>;		# Read it into an array
    close(INFO);
    unlink($fname);
    pop(@lines);
    foreach (@lines) {
      my $line=$_;
      (my $repo)=($line =~ /title='([^']+)'/);
      my $perm = "R";
      if ($repo ne "") {
        my ($aperm, $creator) = &repo_rights($repo);
        $perm=$aperm;
      }
      if ($perm =~ /R/) {
        print $line;
      }
    }
}

sub timestamp {
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year + 1900, $t->mon + 1, $t->mday,
                  $t->hour, $t->min, $t->sec );
}


