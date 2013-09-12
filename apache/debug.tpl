file @H@/usr/local/apps/apache/bin/httpd
set args -X
show args
set breakpoint pending on
b authn_alias_check_password
b authaliassection
run 
