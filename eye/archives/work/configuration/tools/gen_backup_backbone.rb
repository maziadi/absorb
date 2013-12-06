#!/usr/bin/env ruby

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
else
  require_relative 'model'
end

RSNAPSHOT_CONF = "dist/nodes/backup-1-cbv1/etc/rsnapshot/rsnapshot_%d.conf"
STD_EXCLUDES = ['dev', 'proc', 'sys', 'tmp', 'var/tmp', 'var/log', 'var/run', 'var/lock', 'var/cache' ] 
LISOS_EXCLUDES = STD_EXCLUDES + [ 'uml' ] 
DEBIAN_EXCLUDES = STD_EXCLUDES 
CENTREX_EXCLUDES = STD_EXCLUDES + [ 'opt/asterisk' ]
CENTREX_LDC_EXCLUDES = CENTREX_EXCLUDES + [ 'mnt/backup' ]


def gen_excludes(list)
  list.collect { |e| "exclude=#{e}" }.join(',')
end

def gen_scripts(host, scripts)
  res = ""
  scripts.collect { |script|
    case script
    when "mongo-si":
      res += "backup_script\t/opt/local/bin/mongo-si-backup #{host}\t#{host}/mongo\n"
    when "data":
      res += "backup\troot@#{host}:/data\t#{host}/\t\n"
    when "debian":
      res += "backup\troot@#{host}:/\t#{host}/\t#{gen_excludes(DEBIAN_EXCLUDES)}\n"
    when "lisos"
      res += "backup\troot@#{host}:/\t#{host}/\t#{gen_excludes(LISOS_EXCLUDES)}\n"
    when "centrex"
      res += "backup\troot@#{host}:/\t#{host}/\t#{gen_excludes(CENTREX_EXCLUDES)}\n"
    when "centrex_ldc"
      res += "backup\troot@#{host}:/\t#{host}/\t#{gen_excludes(CENTREX_LDC_EXCLUDES)}\n"
    when "ldap":
      res += "backup_script\t/opt/local/bin/slapd-backup #{host}\t#{host}/slapd\n"
    when "mysql":
      res += "backup_script\t/opt/local/bin/mysql-backup-all #{host}\t#{host}/mysql-backup-all\n"
    when "lisos2":
      res += "backup\troot@#{host}:/\t#{host}/\texclude=bin,exclude=dev,exclude=home,exclude=lib,exclude=live/cow,exclude=live/image,exclude=media,exclude=mnt,exclude=mnt,exclude=opt,exclude=proc,exclude=sbin,exclude=selinux,exclude=srv,exclude=sys,exclude=tmp,exclude=usr,exclude=var\n"
    when "pgsql":
      res += "backup_script\t/opt/local/bin/postgresql-backup-all #{host}\t#{host}/postgresql-backup-all\n"
    when /^svn_(.*)/:
      res += "backup_script\t/opt/local/bin/svn-backup #{host} /data/svn/#{$1}\t#{host}/data/svn/#{$1}\n"
    when "windows":
      res += "backup\t/autofs/#{host}\t#{host}/\n"
    when "itf":
      res += "backup\troot@#{host}:/etc/network/interfaces\t#{host}/\t\n"
    when "proxy":
      res += "backup\troot@#{host}:/srv/dansconfig/uploads/\t#{host}/\t\n"
    when "matrix":
      res += "backup_script\t/opt/local/bin/matrix-backup #{host}\t#{host}/matrix_data\n"

    else
      STDERR.print "Argument error on node `#{host}`: #{script}\n"
    end
  }
  res
end

def write_conf(index, hosts, conf_begin = '', conf_end = '')
  File::open(RSNAPSHOT_CONF % index, "w") { |f| 
  	f.write(conf_begin % [index, index, index])
  	hosts.each { |host, val|
      scripts = val.collect { |v| v if v.class == Array }.compact.uniq.flatten
      f.write(gen_scripts(host, scripts))
  	}
  	f.write(conf_end)
  }
end

CONF_BEGIN=<<-EOF
config_version\t1.2
snapshot_root\t/data/backup%d
logfile\t/var/log/rsnapshot%d.log
lockfile\t/var/run/rsnapshot%d.pid
no_create_root\t1
link_dest\t1
ssh_args\t-p 22 -oStrictHostKeyChecking=no -oBatchMode=yes
cmd_cp\t/bin/cp
cmd_rm\t/bin/rm
cmd_rsync\t/usr/bin/rsync
cmd_ssh\t/usr/bin/ssh
cmd_logger\t/usr/bin/logger
cmd_du\t/usr/bin/du
cmd_rsnapshot_diff\t/usr/bin/rsnapshot-diff
rsync_short_args\t-avz
rsync_long_args\t--timeout=500
interval\tdaily\t7
interval\tweekly\t4
interval\tmonthly\t6
verbose\t4
loglevel\t4
use_lazy_deletes\t0
EOF



model = Model::load
hosts = {}
model.find_hosts('', :where => "backup && backup != false").collect { |host| 
  hosts[host.name] = host[:backup].split("+").collect { |profile|
    [[profile]] 
  }.flatten(1)
}

write_conf(0, hosts, CONF_BEGIN)
