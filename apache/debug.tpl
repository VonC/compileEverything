file @H@/usr/local/apps/apache/bin/httpd
set logging file @H@/apache/gdb.txt
set logging on
set args -X
show args
set breakpoint pending on
# authn_alias_check_password
b mod_authn_core.c:115
# authaliassection
b mod_authn_core.c:255
run 
