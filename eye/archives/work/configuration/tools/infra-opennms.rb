#!/usr/bin/env ruby

begin
    require 'cmdparse2'
rescue LoadError => detail
    require 'rubygems'
    require 'cmdparse'
end

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
else
  require_relative 'model'
end

require 'erb'
require 'rexml/document'

def run_cmd(*cmd)
    puts cmd.join(' ')
    unless $dry_run
        system(*cmd)
    end
end

def format_host(host, compact = false, attribute = nil)
    if compact
        if attribute.nil? 
            host.name + ": " + host.children.collect { |key, value|
                "#{key.to_s} = #{value.to_s}"
            }.join(", ") 
        else
            host.name + ": " + host.children[attribute.to_sym].to_s
        end
    else
        host.to_s
    end
end

def search_options(opt)
    opt.on('-e', '--expression EXPRESSION', "Expression to evaluate") { |expression| 
        $expression = expression
    }
    opt.on('-a', '--ancestor ANCESTOR_NAME', "Name of the ancestor to search children for") { |ancestor| 
        $ancestor = ancestor 
    }
end

def do_search()
    Model::load().find_hosts($hostname, 
        :ancestor => $ancestor, :where => $expression)
end

cmd = CmdParse::CommandParser::new(true, true)
cmd.program_name = "infra-opennms.rb "
cmd.program_version = [0, 0, 1]

cmd.add_command(CmdParse::HelpCommand::new, true)
cmd.add_command(CmdParse::VersionCommand::new)

search = CmdParse::Command::new('search', false)
search.short_desc = "Search for an host"
search.description = "Search for an host"
search.description << """
    - by name (regexp),
    - by attribute (expression):
        - 'key == false'
        - 'admin_addr =~ /^217.15.*/'
        - '!check.nil?'
    - by ancestor
"""
search.options = CmdParse::OptionParserWrapper::new do |opt|
    search_options(opt)
    opt.on('-c', '--compact [ATTR]', "Compact output (one host per line)") { |name| 
        $compact = true 
        $attribute = name == "" ? nil : name
    }
end

search.set_execution_block do |args|
    $expression ||= nil
    $ancestor ||= nil 
    $compact ||= false
    $hostname = args.size > 0 ? args.first : ''
    puts do_search().collect { |host|
        format_host(host, $compact, $attribute)
    }.join("\n") 
end

OPENNMS_XML_HEAD = <<-EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model-import last-import="2009-10-16T14:47:15.758+02:00" foreign-source="Alphalink" date-stamp="2009-06-16T14:47:14.398+02:00" xmlns="http://xmlns.opennms.org/xsd/config/model-import">

EOF

OPENNMS_XML_TEMPL_TXT = <<-EOF
 <node node-label="<%= name %>" foreign-id="<%= name %>">
    <interface snmp-primary="P" ip-addr="<%= admin_addr %>" descr="<%= name %>">
      <monitored-service service-name="SNMP"/>
<% if admin_port -%>
      <monitored-service service-name="SSH-<%= admin_port %>"/>
<% else -%>
      <monitored-service service-name="SSH"/>
<% end -%>
    </interface>
    <category name="TEST"/>
    <asset value="<%= name %>" name="comment"/>
    <asset value="" name="address1"/>
    <asset value="" name="building"/>
  </node>
EOF

OPENNMS_XML_BOTTOM = <<-EOF
</model-import>
EOF

OPENNMS_XML_TEMPL = ERB.new(OPENNMS_XML_TEMPL_TXT, 0, "-")

opennms = CmdParse::Command::new('opennms', false)
opennms.short_desc = "Generate provisioning OpenNMS XML file for a group of hosts"
opennms.description = "TODO" # TODO
opennms.options = CmdParse::OptionParserWrapper::new do |opt|
    search_options(opt)
    #opt.on('-n', '--dry-run', "Don't actually do it") { $dry_run = true }
end

opennms.set_execution_block do |args|
    $expression ||= nil
    $ancestor ||= nil
    $hostname = args.size > 0 ? args.first : ''

    raise "Ancestor must be defined" unless $ancestor

    oldnodesfile = REXML::Document.new(File.new('modules/opennms/files/opt/local/share/opennms/Alphalink.xml'))
#   newnodesfile = REXML::Output.new(File.new('/tmp/Alphalink.xml'))
   
    puts oldnodesfile.root()

    hosts = do_search()

    if hosts==[]
      puts "Any node matched from yaml file"
      exit
    end

    hosts.collect! { |host|
      hostexist=false
      oldnodesfile.elements.each("model-import/node") { |element|
        if (element.attributes["node-label"] == host.name)
          hostexist=true
          puts host.name+" yet in OpenNMS, skipping..."
        end
      }
      if hostexist
        nil
      else
        host
      end
    }
    hosts.compact!
#    host_group = $ancestor

    result = hosts.collect { |host|
      b = host.create_binding
#      eval "group = '#{$ancestor}'", b
      OPENNMS_XML_TEMPL.result(b)
    }.join("\n")

    

    targetfile = File.open('/tmp/Alphalink.xml', 'w')
    sourcefile = File.open('modules/opennms/files/opt/local/share/opennms/Alphalink.xml', 'r').readlines
    sourcefile.map! {|line|
      if (line["version"] == "version") or (line["last-import"] == "last-import") or (line["</model-import>"] == "</model-import>")
        nil
      else
        line
      end
    }
    sourcefile.compact!
   
    targetfile.puts OPENNMS_XML_HEAD
    targetfile.puts sourcefile
    targetfile.puts result
    targetfile.puts OPENNMS_XML_BOTTOM
    targetfile.close
    puts "Result is in /tmp/Alphalink.xml"
end

cmd.add_command(search)
cmd.add_command(opennms)
cmd.parse
