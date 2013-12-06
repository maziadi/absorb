worker_processes 2
working_directory "/srv/taxman/"

# This loads the application in the master process before forking
# worker processes
# Read more about it here:
# http://unicorn.bogomips.org/Unicorn/Configurator.html
preload_app true

timeout 30

listen "127.0.0.1:3001", :tcp_nopush => true

pid "/var/run/taxman/unicorn.pid"

stderr_path "/var/log/taxman/unicorn.stderr.log"
stdout_path "/var/log/taxman/unicorn.stdout.log"

#before_fork do |server, worker|
## This option works in together with preload_app true setting
## What is does is prevent the master process from holding
## the database connection
#  defined?(ActiveRecord::Base) and
#    ActiveRecord::Base.connection.disconnect!
#end
#
#after_fork do |server, worker|
## Here we are establishing the connection after forking worker
## processes
#  defined?(ActiveRecord::Base) and
#    ActiveRecord::Base.establish_connection
#end
