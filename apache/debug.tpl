file @H@/usr/local/apps/apache/bin/httpd
set logging file @H@/apache/gdb.txt
set logging on
set args -X
show args
set breakpoint pending on
# modform
#b mod_auth_form.c:786
#b mod_auth_form.c:916
b mod_auth_form.c:1054
run 
fs cmd
