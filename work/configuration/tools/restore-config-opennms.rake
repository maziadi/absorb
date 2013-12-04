desc """Description"""
task :default => :restore_config_opennms do
      puts "Restauration done."
end

def ssh( server, cmd )
      system "ssh #{server} '#{cmd}'"
end

desc """Restore config opennms - copy files from backup server and install to opennms server"""
task :restore_config_opennms do
  raise "Hostname must be defined!\n  Usage: rake -f restore-config-opennms.rake hostname=<hostname>" unless $hostname = ENV["hostname"]

  $ps=`ssh -oStrictHostKeyChecking=no -oBatchMode=yes #{$hostname} ps ax`
  if $ps =~ /opennms_bootstrap/
   system "ssh -oStrictHostKeyChecking=no -oBatchMode=yes #{$hostname} /etc/init.d/opennms stop"
  end

  puts "Retrieving OpenNMS setting from backup server..."
  ssh("root@backup", "rsync -avz /data/backup1/daily.0/maquette-opennms/etc/opennms/* root@#{$hostname}:/etc/opennms")
  puts "Retrieving OpenNMS RRD data from backup server..."
  ssh("root@backup", "rsync -avz /data/backup1/daily.0/maquette-opennms/var/lib/opennms/* root@#{$hostname}:/var/lib/opennms")
  puts "Retrieving OpenNMS database from backup server..."
  ssh("root@backup", "rsync -avz /data/backup1/daily.0/maquette-opennms/postgresql-backup-all/all_databases.dump.bz2 root@#{$hostname}:/tmp")
  puts "Restoring OpenNMS database..."

  ssh($hostname, "rm -f /tmp/all_databases.dump")
  ssh($hostname, "sudo -u postgres dropdb opennms")
  ssh($hostname, "sudo -u postgres createdb -U postgres -E UNICODE opennms")
  ssh($hostname, "bzip2 -d /tmp/all_databases.dump.bz2")
  ssh($hostname, "sudo -u postgres psql -q -f /tmp/all_databases.dump opennms")
  puts "...some psql errors can be ignored..."
  ssh($hostname, "/etc/init.d/opennms start")
end

