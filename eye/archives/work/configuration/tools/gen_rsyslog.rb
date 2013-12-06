#!/usr/bin/env ruby

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
else
  require_relative 'model'
end

require 'erb'

groups = []

rsyslog_conf = Hash.new {|h,k| h[k] = [] }

Model::load().find_hosts.collect do |host| 
  if host[:log]
    logs = host[:log].split("+").sort!
    groups.concat(logs).uniq!
    rsyslog_conf[logs] << host.name
    if host[:admin_addr]
        rsyslog_conf[logs] << host[:admin_addr]
    end
  end
end


rsyslog_template = <<EOF
<% rsyslog_conf.each do |group_log,hosts| %>
if $hostname == [ "<%= hosts.join('",\n\t"') %>" ] then
{
<%  group_log.each do |one_log| %>
\taction(type="omfile" file="/var/log/syslog/<%= one_log %>")
<% end %>
\tstop
}

<% end %>
EOF

render = ERB.new(rsyslog_template,nil,'<>')


File::open("modules/rsyslog_1_0/files/gen_group.conf","w") { |f| f.write(render.result) }

logrotate = <<EOF

{
  rotate 365
  daily
  missingok
  dateext
  dateyesterday
  dateformat _%Y-%m-%d
  notifempty
  compress
  postrotate
  invoke-rc.d rsyslog rotate > /dev/null
  endscript
}
EOF

rsyslog_files = groups.map{|key| "/var/log/syslog/"+key} + ["/var/log/syslog/syslog"]

File::open("modules/rsyslog_1_0/files/logrotate_rsyslog.conf","w"){|f|
    f.write(rsyslog_files.join("\n"))
    f.write(logrotate)
}
