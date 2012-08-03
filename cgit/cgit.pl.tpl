#!@H@/usr/local/apps/perl/bin/perl

BEGIN {
$ENV{HOME} = "@H@";
$ENV{GL_BINDIR} = "$ENV{HOME}/gitolite/bin";
$ENV{GL_LIBDIR} = "$ENV{GL_BINDIR}/lib";
my $remote_user=$ENV{"REMOTE_USER"};
$ENV{GL_USER} = $remote_user || "gitweb";
# set project root etc. absolute paths
$ENV{GL_REPO_BASE_ABS} = "$ENV{HOME}/repositories";
$projects_list = $projectroot = $ENV{GL_REPO_BASE_ABS};
}
unshift @INC, $ENV{GL_LIBDIR};
use lib $ENV{GL_LIBDIR};
use Gitolite::Rc;
#printf "----------- GL_LIBDIR ----------------: '$ENV{GL_LIBDIR}'\n";
use Gitolite::Common;
use Gitolite::Conf::Load;

use Time::localtime;

my $fname="$remote_user.".timestamp().".tpl";

# system("@H@/cgit/cgit.cgi");

my $user = $ENV{GL_USER};
my $path_info=$ENV{"PATH_INFO"};
my $request_uri=$ENV{"REQUEST_URI"}; 

if ($request_uri ne "/cgit/" && $request_uri ne "/cgit/cgit.pl/") {
  (my $repo)=($path_info =~ /\/([^\/]+)/);
  my $perm = "R";
  if ($repo ne "") {
  my $aperm = access( $repo, $user, 'R', 'any' );
  # my ($aperm, $creator) = &repo_rights($repo);
    $perm=$aperm;
  }
  if ($perm !~ /DENIED/) {
    system("@H@/cgit/cgit.cgi");
  }
  else {
    print "Content-type: text/html\n\n";
    print "<html>\n";
    print "<body>\n";
    print " <h1>HTTP Status 403 - Access is denied</h1>\n";
    print " You don't have access to repo <b>$repo</b> as <b>$user</b>\n";
    print "</body>\n";
    print "</html>\n";
  }
  # print "ok: repo $repo<br />";
}
else {
    my $fname="$user.".timestamp().".tpl";
    system("@H@/cgit/cgit.cgi > $fname");
    open(INFO, $fname);     # Open the file
    @lines = <INFO>;        # Read it into an array
    close(INFO);
    unlink($fname);
    pop(@lines);
    foreach (@lines) {
      my $line=$_;
      (my $repo)=($line =~ /title='([^']+)'/);
      my $perm = "R";
      if ($repo ne "") {
        my $aperm = access( $repo, $user, 'R', 'any' );
        # my ($aperm, $creator) = &repo_rights($repo);
        $perm=$aperm;
      }
      if ($perm !~ /DENIED/) {
        print $line;
      }
      # else { print "aaa<br/>"; }
    }
}
=doc
print "<pre>\n";
my $remote_user=$ENV{"REMOTE_USER"}; 
print "REMOTE_USER = $remote_user<br />";
my $path_info=$ENV{"PATH_INFO"}; 
print "PATH_INFO = $path_info<br />";
my $request_uri=$ENV{"REQUEST_URI"}; 
print "REQUEST_URI = $request_uri<br />";
 foreach $key (sort keys(%ENV)) {
   print "$key = $ENV{$key}<p>";
 }
print "</pre>\n";
=cut
sub timestamp {
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                  $t->year + 1900, $t->mon + 1, $t->mday,
                  $t->hour, $t->min, $t->sec );
}
