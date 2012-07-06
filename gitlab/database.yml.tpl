development:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: gitlabhq_development
  pool: 5
  username: root
  password: msandbox
  socket: @MYSQL_gitlab_socket@

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: gitlabhq_test
  pool: 5
  username: root
  password: msandbox
  socket: @MYSQL_gitlab_socket@

production:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: gitlabhq_production
  pool: 5
  username: root
  password: msandbox
  socket: @MYSQL_gitlab_socket@
