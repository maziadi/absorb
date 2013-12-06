#!/usr/bin/env ruby
# == Synopsis
#
# Génère la configuration pour l'accounting RNMen introspectant
# les machines données en argument. 
#
# == Usage
#
# -h, --help:
#    show help
#
# --hostnames [...], -n [...]:
#   comma separated list of hostnames 
#
# --config [filename], -c [filename]:
#   name of the configuration destination file 

require 'ipaddr'
require 'rexml/document'
require 'getoptlong'
require 'rdoc/usage'

include REXML

opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
        [ '--hostnames', '-n', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--config', '-c', GetoptLong::REQUIRED_ARGUMENT ]
        )

hostnames = nil
filename = nil
opts.each do |opt, arg|
    case opt
        when '--help'
            RDoc::usage
        when '--hostnames'
            hostnames = arg.split(',')
        when '--config'
            filename = arg
    end
end

if !hostnames and !filename 
    puts "Try --help..."
    exit(-1) 
end

xml_config_template = File.open('data/accounting_config_template.xml') { |file|
    REXML::Document::new(file)
}

interfaces = {} 
hostnames.each { |host|
    puts "Collecting interfaces on host '#{host}'..."
    data = `ssh #{host} ip link`
    data = data.split(/\n/).grep(/^[0-9]/)
    data = data.collect { |line| 
        line.split(/:/)[1].strip
    }.grep(/(bond.*|nas.*)/).sort
    puts data.join(', ')
    interfaces[host] = data
}

net_elt = xml_config_template.root.add_element('network', 'name' => 'Auto')
interfaces.each_pair { |host, ifs|
    elt = net_elt.add_element('host', 'name' => host)
    elt = elt.add_element('interface', 'name' => '*')
    elt = elt.add_element('address', 'name' => IPSocket.getaddress("#{host}.admin.alphalink.fr")) # TODO
    elt = elt.add_element('service', 'name' => 'snmp', 'class' => 'SnmpService', 'managed' => 'true')
    elt.add_element('param', 'name' => 'community').text = 'monitor' # TODO
    ifs.each { |interface| 
        name = interface.gsub(/@.*/, '')
        mon_elt = elt.add_element('monitor', 'name' => name, 'class' => 'SnmpBandwidth95Monitor')
        mon_elt.add_element('param', 'name' => 'device_name', 'value' => name)
        mon_elt.add_element('param', 'name' => 'warning').text = '100'
        mon_elt.add_element('param', 'name' => 'critical').text = '200'
    }
}

xml_config_template.write(File::new(filename, 'w'))
