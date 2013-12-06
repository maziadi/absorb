#!/usr/bin/env ruby

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/dns_utils'
else
  require_relative 'dns_utils'
end

require 'erb'
require 'yaml'

DEFAULT = 'reverse.alphalink.fr'
ZONE_TEMPL = ERB.new <<-EOF
$ORIGIN .
$TTL 86400  ; 1 day
<%= zone %>.in-addr.arpa IN SOA  ns1.alphalink.fr. hostmaster.alphalink.fr. (
                <%= serial %> ; serial
                10800      ; refresh (3 hours)
                3600       ; retry (1 hour)
                1209600    ; expire (2 weeks)
                86400      ; minimum (1 day)
                )
            NS  ns1.alphalink.fr.
            NS  ns2.alphalink.fr.
$ORIGIN <%= zone %>.in-addr.arpa.
<% reverses.each do |num, name| 
name = [name] unless name.kind_of? Array
%>
<%= num %> PTR <%= name.join(".\n    PTR ") %>.<% end %>
EOF

class ZoneData
  attr_reader :zone, :serial, :reverses

  def reverse(ip)
    ip.split('.').reverse.join('.')
  end

  def initialize(*args)
    @zone, @serial, @reverses = args
    @zone = reverse(@zone)
  end

  def to_s
    "Zone #{@zone}: serial = #{serial}"
  end

  def get_binding
    binding
  end
end

def gen_zone(zone, serial, reverses)
    default = reverses.has_key?(:default) ? reverses.delete(:default) : DEFAULT 
    descr = reverses.delete(:descr)
    (0..255).each { |i| 
        reverses[i] ||= "#{i}-#{zone.split('.').reverse.join('-')}.#{default}" 
    }
    reverses = reverses.sort
    zone_data = ZoneData::new(zone, serial, reverses)
    file = "#{PRI_DIR}/#{zone_data.zone}.zone" 
    puts "Generating zone #{zone_data.zone} into #{file}"
    
    File::open(file, "w") { |f| 
        f.write(ZONE_TEMPL.result(zone_data.get_binding))
    }
end

if (ARGV.length != 2) || (ARGV[0].length != 2) || !(/[0-9]+\.[0-9]+\.[0-9]+/ =~ ARGV[1])
  puts "Usage: gen_reverse.rb <SERIAL SUFFIX> <zone 3 first digits>"
  exit -1
end


serial = Time::now().strftime('%Y%m%d') + ARGV[0] 
zone = ARGV[1]

all_zones = YAML::load(File::new('data/reverses.yaml'))

unless (all_zones.has_key?(zone))
  puts "Unable to find zone '#{zone}'"
  exit(-1)
end

gen_zone(zone, serial, all_zones[zone] || {})

File::open("#{PRI_ETC_DIR}/pri_reverse.files", "w") { |f| 
    all_zones.keys.sort.each { |key|
        data = ZoneData::new(key, serial, [])
        f.write(%Q|zone "#{data.zone}.in-addr.arpa" IN {\n  type master;\n  file "pri/#{data.zone}.zone";\n};\n|)
    }
}

File::open("#{SEC_ETC_DIR}/sec_reverse.files", "w") { |f| 
    all_zones.keys.sort.each { |key|
        data = ZoneData::new(key, serial, [])
        f.write(%Q|zone "#{data.zone}.in-addr.arpa" IN {\n  type slave;\n  file "sec/#{data.zone}.zone";\n  masters { "alphalink"; };\n};\n|)
    }
}
