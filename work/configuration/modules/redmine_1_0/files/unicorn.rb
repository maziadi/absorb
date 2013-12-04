worker_processes 2
working_directory "/usr/share/redmine/"

# This loads the application in the master process before forking
# worker processes
# Read more about it here:
# http://unicorn.bogomips.org/Unicorn/Configurator.html
preload_app true

timeout 30

# This is where we specify the socket.
# We will point the upstream Nginx module to this socket later on
#listen "/usr/share/redmine/unicorn.sock", :backlog => 64
listen "127.0.0.1:3000"

pid "/var/run/redmine/unicorn.pid"

# Set the path of the log files inside the log folder of the testapp
stderr_path "/var/log/redmine/default/unicorn.stderr.log"
stdout_path "/var/log/redmine/default/unicorn.stdout.log"

before_fork do |server, worker|
# This option works in together with preload_app true setting
# What is does is prevent the master process from holding
# the database connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
# Here we are establishing the connection after forking worker
# processes
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
