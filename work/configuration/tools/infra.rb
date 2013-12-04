#!/usr/bin/env ruby

begin
    require 'cmdparse2'
rescue LoadError => detail
    require 'rubygems'
    require 'cmdparse'
end

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
  require 'tools/libalpha'
else
  require_relative 'model'
  require_relative 'libalpha'
end
require 'erb'

DOMAIN = 'admin.alphalink.fr'

def run_cmd(*cmd)
    puts cmd.join(' ')
    unless $dry_run
        system(*cmd)
        if $?.signaled? && $?.termsig == Signal.list['INT']
          puts "INT caught, interrupt once more to exit..."
          sleep 2
        end
    end
end

def format_host(host, compact = false, attribute = nil)
    if compact
        if attribute.nil? 
            host.name + ": " + host.children.collect { |key, value|
                "#{key.to_s} = #{value.to_s}"
            }.join(", ") 
        elsif attribute == 'NONE'
            host.name
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
cmd.program_name = "infra.rb"
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
    opt.on('-c', '--compact [ATTR]', "Compact output (one line per host)",
          "ATTR: print this key (NONE to print only hostnames)") { |name| 
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

rexec = CmdParse::Command::new('rexec', false)
rexec.short_desc = "Execute a command for a group of hosts"
rexec.description = "Execute a command on each host returned by the search for an host"
rexec.options = CmdParse::OptionParserWrapper::new do |opt|
    search_options(opt)
    opt.on('-c', '--command COMMAND', "Command to execute on the selected hosts") { |command| 
        $command = command
    }
    opt.on('-n', '--dry-run', "Don't actually do it") { $dry_run = true }
  
end
rexec.set_execution_block do |args|
    $expression ||= nil
    $ancestor ||= nil 
    $hostname = args.size > 0 ? args.first : ''
    if $command.nil?
        puts "--command, -c is mandatory"
        exit(-1)
    end
    do_search().collect { |host|
        puts "-" * 80
        run_cmd "ssh '#{host.name}' '#{$command}'"
#        run_cmd "ssh -oConnectTimeout=2 -oNumberOfPasswordPrompts=0 -oStrictHostKeyChecking=false '#{host.name}' '#{$command}'"
    }
end

$actions = Array::new()
$comments = Array::new()
$histories = Array::new()
mail = CmdParse::Command::new('mail', false)
mail.short_desc = "Send report to infra@alphalink.fr"
mail.description = "example:
        tools/infra.rb mail -m a.moutot@alphalink.fr -s \"Mise en place du DNS sip.openvno.net vers PCSCF-C5\" -a \"sip.openvno.net pointe dorenavant vers 217.15.80.163 : adresse ip du PCSCF-C5\" -a \"ajout dans la table domain du pcscf-c5 de sip.openvno.net\" -t 5min -t aucun -t 12h00 "
mail.options = CmdParse::OptionParserWrapper::new do |opt|
  opt.on('-n', '--dry-run', "Don't actually do it") { $dry_run = true }
  opt.on('-d', '--date DATE', "date of action") { |date| $date = date }
  opt.on('-s', '--subject SUBJECT', "Subject of action") { |subject| $subject = subject }
  opt.on('-O', '--off-time', "Tag action as off time (HNO)") { $hno = true }
  opt.on('-a', '--action ACTION', "Description of action(s) : MULTI") { |action| $actions.push(action) }
  opt.on('-c', '--comments COMMENT', "Comments about operation : TODO") { |comments| $comments.push(comments) }
  opt.on('-t', '--histories HISTORY', "Historic about operation (need 3 elements (duration/impact/action's hour))") { |history| $histories.push(history) }
  opt.on('-m', '--mail EMAIL', "Mail of sender") { |mail| $mail = mail }
end
mail.set_execution_block do |args|
  require 'tmail'
  require 'net/smtp'

  $date ||=  Time::new().strftime("%d/%m/%Y")
  $mail ||= `id -un`.chomp+"@alphalink.fr"
  $hno ||= false

  if $subject.nil?
    puts "--subject, -s is mandatory"
    exit(-1)
  elsif $actions.size < 1
    puts "--action, -a is mandatory"
    exit(-1)
  elsif $histories.size < 3
    puts "--histories, -t is mandatory (need 3 elements (duration/impact/action's hour))"
    exit(-1)
  end
  subject =  "Compte Rendu d'intervention du #{$date} " + ($hno ? "[HNO] " : "") + ": #{$subject}"
  body =  "Bonjour,

Vous trouverez ci-dessous le compte rendu de l'intervention du #{$date}.

Actions menees :
" + $actions.collect { |op| "- #{op}" }.join("\n") + "

Commentaires :
" + $comments.collect { |com| "- #{com}" }.join("\n") + "

Historique :
- duree d'intervention : #{$histories[0]}
- impacts : #{$histories[1]}
- heure d'intervention : #{$histories[2]}
" + $histories[3..-1].collect { |h| "- #{h}" }.join("\n") + "
Cordialement,

#{$mail}"
  if $dry_run
    puts "Subject::\n#{subject}"
    puts "Body::\n#{body}"
  else
    send_mail("smtp.alphalink.fr", "infra@alphalink.fr", $mail, subject, body)
  end
end

NAGIOS_TEMPL_TXT = <<-EOF
define host {
    use generic-host
    host_name <%= name %>  
    alias <%= name %> 
    address <%= admin_addr || admin_name %> 
<% if admin_port -%>
<% else -%>
    check_command           check_ssh
<% end -%>
}

define service {
    use generic-service
    host_name <%= name %> 
    contact_groups          admins, <%= group %>
<% if admin_port -%>
    check_command           check_ssh_with_port!<%= admin_port %>
<% else -%>
    check_command           check_ssh
<% end -%>
}
EOF
NAGIOS_TEMPL = ERB.new(NAGIOS_TEMPL_TXT, 0, "-")

HOST_GROUP_TEMPL = ERB.new <<-EOF
define hostgroup {
    hostgroup_name <%= host_group %> 
    alias  <%= host_group %>
    members <%= hosts.collect { |h| h.name }.join(', ') %> 
    contact_groups admins,<%= host_group %>
}
EOF

nagios = CmdParse::Command::new('nagios', false)
nagios.short_desc = "Generate nagios config for a group of hosts"
nagios.description = "TODO" # TODO
nagios.options = CmdParse::OptionParserWrapper::new do |opt|
    search_options(opt)
    #opt.on('-n', '--dry-run', "Don't actually do it") { $dry_run = true }
  
end
nagios.set_execution_block do |args|
    $expression ||= nil
    $ancestor ||= nil
    $hostname = args.size > 0 ? args.first : ''

    raise "Ancestor must be defined" unless $ancestor
    
    hosts = do_search()
    host_group = $ancestor 

    result = hosts.collect { |host|
        b = host.create_binding
        eval "group = '#{$ancestor}'", b
        NAGIOS_TEMPL.result(b)
    }.join("\n")
    result += "\n" + HOST_GROUP_TEMPL.result(binding)

    puts result
end

issue = CmdParse::Command::new('issue', false)
issue.short_desc = "Display /etc/issue"
issue.description = "Display Alphalink /etc/issue"
issue.set_execution_block do |args|
    model = Model::load()
    name_sizes, sizes, hosts = [], [], [] 
    headers = model.collect {|group| group.name }
    model.collect.each_with_index { |group, i|
        ns, s = headers[i].size, 0
        hosts << group.find_hosts().collect { |host| 
            ns = host.name.size > ns ? host.name.size : ns 
            s += 1 
            host.name 
        }
        name_sizes << ns    
        sizes << s
    }
    max = sizes.max
    hosts.each { |l| l.concat Array::new(max - l.size) }
    fmt = name_sizes.collect { |s| "%-#{s}s" }.join(" | ")
    
    puts(fmt % headers)
    puts("-" * (name_sizes.inject(0) { |s,v| s + v } + (sizes.size - 1) * 3))
    max.times { |i|
        puts(fmt % hosts.collect { |host_names| host_names[i] })
    }
end


xen_prov = CmdParse::Command::new('xen-prov', false)
xen_prov.short_desc = "Provision a xen guest"
xen_prov.description = "Execute a command on each host returned by the search for an host"
xen_prov.options = CmdParse::OptionParserWrapper::new do |opt|
    search_options(opt)
    opt.on('-d', '--dom0 DOM0_HOSTNAME', "Provision on the given host") { |dom0| 
        $dom0 = dom0
    }
    opt.on('-m', '--memory MEMORY', "Memory to allocate to the domU (MB)") { |memory| 
        $memory = memory.to_i
    }
    opt.on('-s', '--size DISK_SIZE', "Disk size to allocate to the domU (ex: 10G)") { |size| 
        $size = size
    }
    opt.on('-w', '--swap DISK_SIZE', "Swap size to allocate to the domU (MB)") { |size| 
        $swap = size
    }
    opt.on('-b', '--bridges BRIDGE0,BRIDGE1', "List of bridge names separated with commas") { |bridges| 
        $bridges = bridges.split(',')
    }
    opt.on('-n', '--dry-run', "Don't actually do it") { $dry_run = true }
  
end
xen_prov.set_execution_block do |args|
    $expression ||= nil
    $ancestor ||= nil 
    $hostname = args.size > 0 ? args.first : ''
    $memory ||= 256
    $swap ||= $memory * 2
    $size ||= "10G"
    $bridges ||= ['br99', 'br98'] 

    if $dom0.nil?
        puts "--dom0, -d is mandatory"
        exit(-1)
    end
    res = do_search().collect { |host|
        puts "-" * 80
        hostname = "#{host.name}.#{DOMAIN}"
        hostname1="#{host.name}" 
	cfgfile = "/etc/xen/#{hostname}.cfg"

        cmd = ['ssh', $dom0, 'xen-create-image']
        cmd << ['--hostname', hostname]
        cmd << ['--ip', host[:admin_addr]]
        cmd << ['--gateway', host[:admin_addr].gsub(/\.[0-9]+$/, ".1")]
        cmd << ['--netmask', "255.255.254.0"]
        cmd << ['--size', $size]
        cmd << ['--memory', $memory.to_s]
        cmd << ['--swap', $swap.to_s]
        cmd << ['--passwd']

        run_cmd *cmd.flatten.compact
        br = $bridges.collect { |br| "'bridge=#{br}'" }.join(", ")
        run_cmd "ssh", $dom0, 'sed',  '-i',  %q{"s/^ *vif *=.*$/vif = [} + br + %q{]/"}, cfgfile
        sleep 5 unless $dry_run
        run_cmd "ssh '#{$dom0}' 'xm destroy `xm domid #{hostname}`'"
        run_cmd "ssh '#{$dom0}' xm create #{cfgfile}"
        sleep 30 unless $dry_run
        run_cmd "./tools/puppetize #{hostname} #{hostname.gsub(/\..*$/, '')}"
    }
end

cmd.add_command(issue)
cmd.add_command(search)
cmd.add_command(rexec)
cmd.add_command(mail)
cmd.add_command(nagios)
cmd.add_command(xen_prov)
cmd.parse
