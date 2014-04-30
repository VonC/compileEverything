input {
  file {
    type => "Apache Git @HOMED@ (@FQN@)"
    path => [ "@H@/apache/*error_log" ]
  }
  file {
    type => "NGiNX Git @HOMED@ (@FQN@)"
    path => [ "@H@/nginx/ng/logs/error.log" ]
  }
}
output {
  stdout { codec => rubydebug }
  elasticsearch {
    embedded => true
    node_name => @FQN@
  }
}

