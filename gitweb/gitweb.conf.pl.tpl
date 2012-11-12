# --------------------------------------------
# Per-repo authorization based on gitolite ACL

BEGIN { 
$ENV{HOME} = "@H@"; 
$ENV{GL_BINDIR} = "$ENV{HOME}/gitolite/bin"; 
$ENV{GL_LIBDIR} = "$ENV{GL_BINDIR}/lib"; 
$ENV{GL_USER} = $cgi->remote_user || "gitweb"; 
open FILE, "$ENV{HOME}/.ssh/authorized_keys";
while ($line=<FILE>){
  if ($line=~/gitolite-shell ([\S]+)",no.*? $ENV{GL_USER}$/){
    $ENV{GL_USER} = $1;
    last;
  }
}
close(FILE);
#die "----------- GL_USER! ----------------: '$ENV{GL_USER}'\n";
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

#$ENV{GL_USER} = $cgi->remote_user || "gitweb"; 
#die "GL_USER='$ENV{GL_USER}'";

$export_auth_hook = sub {
    my $repo = shift;
    my $user = $ENV{GL_USER};
    # gitweb passes us the full repo path; so we strip the beginning
    # and the end, to get the repo name as it is specified in gitolite conf
    return unless $repo =~ s/^\Q$projectroot\E\/?(.+)\.git$/$1/;

    #die "GL_USER='$ENV{GL_USER}', repo='$repo'";
    #die "repo='$repo', user='$user'";
    # check for (at least) "R" permission
    my $ret = &access( $repo, $user, 'R', 'any' );
    #my $ret = &repo_rights($repo);
    my $res = $ret !~ /DENIED/;
    #die "GL_USER='$ENV{GL_USER}', repo='$repo', ret='$ret', res='$res'";
    return ($ret !~ /DENIED/);
};

