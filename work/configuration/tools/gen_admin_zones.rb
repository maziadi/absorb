#!/usr/bin/env ruby

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
else
  require_relative 'model'
end

require 'ipaddr'

if ARGV.length != 1 || ARGV[0].length != 2
  puts "Usage: gen_admin_zones.rb <SERIAL SUFFIX>"
  exit -1
end

PRI_DIR = "dist/services/dns/primary/var/bind/pri"
SERIAL = Time::now().strftime('%Y%m%d') + ARGV[0] 

ADMIN = """$ORIGIN .
$TTL 604800     ; 1 week
admin.alphalink.fr      IN SOA  ns1.alphalink.fr. root.alphalink.fr. (
                                #{SERIAL} ; serial
                                28800      ; refresh (8 hours)
                                3600       ; retry (1 hour)
                                604800     ; expire (1 week)
                                900        ; minimum (1 day)
                                )
$TTL 259200     ; 3 days
                        NS      ns1.alphalink.fr.
                        NS      ns2.alphalink.fr.
$TTL 604800     ; 1 week
                        MX      5 mail.admin.alphalink.fr.
$ORIGIN admin.alphalink.fr.
mail	CNAME zimbra.alphalink.fr.

av      A 169.254.0.165 
        A 169.254.1.165 

"""

ZERO_PREFIX = """$ORIGIN .
$TTL 86400      ; 1 day
0.254.169.in-addr.arpa  IN SOA  ns1.alphalink.fr. hostmaster.alphalink.fr. (
                                #{SERIAL} ; serial
                                10800      ; refresh (3 hours)
                                3600       ; retry (1 hour)
                                1209600    ; expire (2 weeks)
                                900        ; minimum (1 day)
                                )
                        NS      r-ns1.alphalink.fr.
                        NS      r-ns2.alphalink.fr.

$ORIGIN 0.254.169.in-addr.arpa.
"""

ONE_PREFIX = """$ORIGIN .
$TTL 86400      ; 1 day
1.254.169.in-addr.arpa  IN SOA  ns1.alphalink.fr. hostmaster.alphalink.fr. (
                                #{SERIAL} ; serial
                                10800      ; refresh (3 hours)
                                3600       ; retry (1 hour)
                                1209600    ; expire (2 weeks)
                                86400      ; minimum (1 day)
                                )
                        NS      r-ns1.alphalink.fr.
                        NS      r-ns2.alphalink.fr.

$ORIGIN 1.254.169.in-addr.arpa.
"""

def compute_zone(addr_prefix, prefix, entries) 
    prefix + entries.find_all { |entry|
        Regexp::new("^#{addr_prefix}") =~ entry[0]
    }.collect { |entry|
        "#{entry[0].gsub(/.*\./, "")}\t\tPTR\t#{entry[1]}.admin.alphalink.fr."
    }.join("\n") + "\n"
end

entries = Model::load().find_hosts.collect { |host| 
  if host[:admin_addr] 
    [host[:admin_addr], host.name, :addr] 
  elsif host[:admin_name]
    [host[:admin_name], host.name, :name] 
  end
}.compact.sort { |a, b|
  if a[2] == :name || b[2] == :name
    a[0] <=> b[0]
  else
    IPAddr::new(a[0]).to_i() <=> IPAddr::new(b[0]).to_i()
  end
}

admin_zone = ADMIN + entries.collect {|entry| 
  if entry[2] == :addr
    "#{entry[1]}\t\tA\t#{entry[0]}" 
  elsif entry[2] == :name
    "#{entry[1]}\t\tCNAME\t#{entry[0]}." 
  else 
    raise ArgumentError, "Unkown type: #{entry[2]}"
  end
}.join("\n") + "\n"
zero_zone = compute_zone('169.254.0', ZERO_PREFIX, entries)
one_zone = compute_zone('169.254.1', ONE_PREFIX, entries)

File::open("#{PRI_DIR}/admin.alphalink.fr.zone", "w") { |f| f.write(admin_zone) }
File::open("#{PRI_DIR}/0.254.169.zone", "w") { |f| f.write(zero_zone) }
File::open("#{PRI_DIR}/1.254.169.zone", "w") { |f| f.write(one_zone) }
