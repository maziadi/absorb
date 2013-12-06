#!/usr/bin/env ruby

require 'rubygems'
require 'sequel'
require 'yaml'
require 'prov_hss'
Prov::Hss::establish_connection(:adapter => 'postgres',
                                :host => 'localhost',
                                :database => 'opensips',
                                :username => 'opensips',
                                :password => 'iApg4jEk')

require 'erb'
require 'cmdparse2'
LocationsRegex = /'(location|[dD][0-9]{12}_loc)'/
SlonyPath = '/etc/slony1/slon_tools.conf'

def my_template(infile, outfile, mode = 0640)
  templ = ERB::new(File.read(infile),nil,'<>')
  txt = templ.result(binding)
  File::open(outfile, "w", mode) { |f| f.write txt }
  #txt
end

def create_media_groups_from_yaml(vno_id, yaml_file)
  mgs = YAML.load(File.open(yaml_file))
  mgs.each do |k,v|
    begin
      configurator = Prov::Hss::MediaGroupConfigurator.new
      configurator.params = { :id => k }
      configurator.data = v
      configurator.create_vno_or_c5(vno_id)
    rescue Sequel::DatabaseError => e
      puts "Error while processing '#{k}'\n#{e.message}"
    end
  end
end

def vno_sql()
  vno_tables = %w(act dom loc rt sub adr dr_gw dr_rl dr_cr dr_gr).map {|t| "#{$vno_id}_#{t}"}
  table_regex = vno_tables.join('|')
  current_tables = `/usr/bin/psql -t -U postgres opensips -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name~'#{table_regex}';"`.map {|i| i.strip}
  print "Generating opensips' postgresql config...\n"
  vno_tables.each do |table|
    table_type = table[/_(\w+(_\w+)*)$/,1]
    my_template("sql/#{table_type}.sql", "/root/vno/sql/#{$vno_id}_#{table_type}.sql")
    if current_tables.include? table
      STDERR.puts "#{table} allready exists, skipped."
    else
      print "Importing opensips' postgresql config, #{table} ...\n"
      `/usr/bin/psql -U postgres opensips < /root/vno/sql/#{table}.sql`
    end
  end
end

def vno_opensips()
  print "Generating opensips config...\n"
  my_template("VNO_opensips.cfg", "/etc/opensips/#{$vno_id}_opensips.cfg")
  print "Generating opensips default config...\n"
  my_template("VNO_opensips_default", "/etc/default/#{$vno_id}_opensips")
  print "Generating opensips init script...\n"
  my_template("VNO_opensips_init", "/etc/init.d/#{$vno_id}_opensips", 0755)
  print "Generating opensips' control script...\n"
  my_template("VNO_opensipsctl.erb", "/opt/local/bin/#{$vno_id}_opensipsctl", 0755)
  print "Generating opensips' control script's configuration...\n"
  my_template("VNO_opensipsctlrc.erb", "/etc/opensips/#{$vno_id}_opensipsctlrc", 0644)
  `mkdir -p /usr/lib/opensips/#{$vno_id}_opensipsctl/` unless File.directory?("/usr/lib/opensips/#{$vno_id}_opensipsctl/")
  `cp -r VNO_usr_lib_opensips/* /usr/lib/opensips/#{$vno_id}_opensipsctl/`
  my_template("VNO_opensipsctl.base.erb", "/usr/lib/opensips/#{$vno_id}_opensipsctl/opensipsctl.base")
  `chmod 644 /usr/lib/opensips/#{$vno_id}_opensipsctl/* /usr/lib/opensips/#{$vno_id}_opensipsctl/dbtextdb/dbtextdb.py`
  `chmod 755 /usr/lib/opensips/#{$vno_id}_opensipsctl/dbtextdb`
  print "Generating opensips' monit config...\n"
  $mail_domain_name = "#{`grep -q '^[[:space:]]*environment = development' /etc/puppet/puppet.conf && echo -n dev.`}admin.alphalink.fr"
  my_template("VNO_opensips_monit", "/etc/monit/conf.d/#{$vno_id}_opensips")
  `monit reload`
  print " Adding system startup for /etc/init.d/#{$vno_id}_opensips...\n"
  `update-rc.d #{$vno_id}_opensips defaults 23`
end

def vno_mrfc4_sql()
  print "Generating opensips' postgresql config for mrfc4 ...\n"
  my_template("C4_media_groups.yaml", "/root/vno/#{$vno_id}_media_groups.sql")
  print "Importing opensips' postgresql config for mrfc4 ...\n"
  create_media_groups_from_yaml($vno_id, "/root/vno/#{$vno_id}_media_groups.sql")
  vno_slony
end

def vno_slony()
  $locations = (File.read(SlonyPath).scan(LocationsRegex) + [['location'], ["#{$vno_id}_loc"]]).uniq.sort
  my_template('slon_tools.conf.erb', '/etc/slony1/slon_tools.conf')
  puts "Pensez à lancer refresh.sh dist/nodes/#{`hostname`.strip}/etc/slony1/slon_tools.conf pour ne pas perdre la conf slony1 au prochain coup de puppet."
end

cmd = CmdParse::CommandParser::new(true, true)
cmd.program_name = "vno.rb"
cmd.program_version = [0, 0, 2]

cmd.add_command(CmdParse::HelpCommand::new, true)
cmd.add_command(CmdParse::VersionCommand::new)

prov = CmdParse::Command::new('prov', false)
prov.short_desc = "Provision a VNO"
prov.description = "Provision opensips' base configuration for a VNO and launch it"
prov.description << """
  Example:
    ./vno.rb prov -i D201005050001 -a 217.15.80.171
"""

$opensips_shared_memory = 64
$opensips_private_memory = 4
prov.options = CmdParse::OptionParserWrapper::new do |opt|
  opt.on('-i', "--vno-id [VNO_ID]", "Specify vno_id") { |vno_id|
    $vno_id = vno_id.downcase
  }
  opt.on('-a', "--opensips-service-addr [ADDR]", "Specify opensips service addr") { |service_addr|
    $opensips_service_addr = service_addr
  }
  opt.on('-m', "--opensips-shared-memory [INT]", "Specify opensips shared memory") { |mem|
    $opensips_shared_memory = mem
  }
  opt.on('-M', "--opensips-private-memory [INT]", "Specify opensips private memory") { |mem|
    $opensips_private_memory = mem
  }
end

prov.set_execution_block do |args|
  if($vno_id.nil? || $opensips_service_addr.nil?)
    STDERR.print("Missing arguments\n")
    exit(1)
  end

  vno_sql
  vno_opensips
end

prov_mrfc4 = CmdParse::Command::new('prov_mrfc4', false)
prov_mrfc4.short_desc = "Provision a VNO mrfc4 rules"
prov_mrfc4.description = "Provision opensips' VNO mrfc4 rules"
prov_mrfc4.description << """
  Example:
    ./vno.rb prov_mrfc4 -i D201005050001
"""

prov_mrfc4.options = CmdParse::OptionParserWrapper::new do |opt|
  opt.on('-i', "--vno-id [VNO_ID]", "Specify vno_id") { |vno_id|
    $vno_id = vno_id.downcase
  }
end

prov_mrfc4.set_execution_block do |args|
  if($vno_id.nil?)
    STDERR.print("Missing arguments\n")
    exit(1)
  end

  vno_mrfc4_sql
end

cmd.add_command(prov)
cmd.add_command(prov_mrfc4)
cmd.parse
