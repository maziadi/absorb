#!/usr/bin/env ruby

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
else
  require_relative 'model'
end
require 'ipaddr'
require 'erb'

if ARGV.length != 1 || ARGV[0].length != 2
  puts "Usage: gen_ags_zones.rb <SERIAL SUFFIX>"
  exit -1
end

SERVICE_DIR = "dist/services/dns"
PRI_ETC_DIR = "#{SERVICE_DIR}/primary/etc/bind"
SEC_ETC_DIR = "#{SERVICE_DIR}/secondary/etc/bind"
PRI_DIR = "#{SERVICE_DIR}/primary/var/bind/pri"

SERIAL = Time::now().strftime('%Y%m%d') + ARGV[0] 

template = ERB.new <<-EOF 
$ORIGIN .
$TTL 604800     ; 1 week
<%= domain %>      IN SOA  ns1.alphalink.fr. root.alphalink.fr. (
                                <%= SERIAL %> ; serial
                                28800      ; refresh (8 hours)
                                3600       ; retry (1 hour)
                                604800     ; expire (1 week)
                                86400      ; minimum (1 day)
                                )
$TTL 259200     ; 3 days
                        NS      ns1.alphalink.fr.
                        NS      ns2.alphalink.fr.
$TTL 604800     ; 1 week
                        MX      5 mail.<%= domain %>. 
                        MX      10 mail.alphalink.fr.
$ORIGIN <%= domain %> 
www         A   83.138.141.243	
mail        A   217.15.80.76
EOF

pri_file_template = ERB.new <<-EOF
zone "<%= domain %>" IN {
    type master;
    file "pri/<%= domain %>.zone";
    allow-transfer { "slaves"; };
    notify yes;
};

EOF

sec_file_template = ERB.new <<-EOF
zone "<%= domain %>" IN {
    type slave;
    file "sec/<%= domain %>.zone";
    masters { "alphalink"; };
};

EOF

ldif_template = ERB.new <<-EOF
dn: cn=<%= domain %>,ou=domains,ou=alphalink,dc=init-sys,dc=com
cn: <%= domain %>
amavisBypassSpamChecks: TRUE
mail: @<%= domain %>
objectClass: mailDomain
objectClass: amavisAccount
amavisBypassVirusChecks: TRUE

EOF

pri_files = ""
sec_files = ""
ldif_files = ""
[ 
	'archiverseul.com',
	'archiverseul.fr',
	'archiverseul.eu',
	'archiverseul.asia',
	'archivezseul.com',
	'archivezseul.fr',
	'archivezseul.eu',
	'archivezseul.asia',
].each { |domain|
    File::open("#{PRI_DIR}/#{domain}.zone", "w") { |f| 
        f.write(template.result(binding)) 
    }
    pri_files << pri_file_template.result(binding)
    sec_files << sec_file_template.result(binding)
    ldif_files << ldif_template.result(binding)
 
}

File::open("#{PRI_ETC_DIR}/ags_zone.files", "a") { |f|
    f.write pri_files
}

File::open("#{SEC_ETC_DIR}/ags_zone.files", "a") { |f|
    f.write sec_files
}

puts ldif_files
