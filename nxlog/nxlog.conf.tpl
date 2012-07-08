## This is a sample configuration file. See the nxlog reference manual about the
## configuration options. It should be installed locally under
## /usr/share/doc/nxlog-ce/ and is also available online at
## http://nxlog.org/nxlog-docs/en/nxlog-reference-manual.html

########################################
# Global directives                    #
########################################
User @USERNAME@
Group @GROUPNAME@

LogFile @H@/nxlog/nxlog.log
LogLevel INFO
PidFile @H@/nxlog/nxlog.pid

########################################
# Modules                              #
########################################
<Extension syslog>
    Module      xm_syslog
</Extension>

<Input in1>
    Module	im_udp
    Port	1514
    Exec	parse_syslog_bsd();
</Input>

<Input in2>
    Module	im_tcp
    Port	1514
</Input>

<Output fileout1>
    Module	om_file
    File	"@H@/nxlog/logmsg.txt"
    Exec	if $Message =~ /error/ $SeverityValue = syslog_severity_value("error");
    Exec	to_syslog_bsd();
</Output>

<Output fileout2>
    Module	om_file
    File	"@H@/nxlog/logmsg2.txt"
</Output>

########################################
# Routes                               #
########################################
<Route 1>
    Path	in1 => fileout1
</Route>

<Route tcproute>
    Path	in2 => fileout2
</Route>

