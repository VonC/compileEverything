file @H@/usr/local/apps/apache/bin/httpd
set logging file @H@/apache/gdb.txt
set logging on
set args -X
show args
set breakpoint pending on
# modform
b mod_auth_form.c:1057
run 
fs cmd
