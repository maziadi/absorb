#!/usr/bin/env ruby -w

require 'yaml'

Domu = Struct::new(:hostname, :memory, :vcpu, :bridge, :size, :target)
servers =    [
    Domu.new( "bgp-1-alsatis", 512, 1, [ "br1010", "br1700", "br1701", "br2291" ], 80, "xen-2-cbv1" ),
    Domu.new( "backup-jes", 256, 1, [ "br99", "br30" ], 15, "xen-2-cbv1" ),
    Domu.new( "builder-1-grp-alpha", 1024, 1, [ "br99", "br20" ], 20, "xen-2-cbv1" ),
    Domu.new( "builder-2-grp-alpha", 1024, 1, [ "br99" ], 20, "xen-2-cbv1" ),
    Domu.new( "centrex-test-grp-alpha", 512, 1, [ "br99", "br710"], 10, "xen-2-cbv1" ),
    Domu.new( "im-1-cbv2", 256, 2, [ "br99" ], 12, "xen-2-cbv1" ),
    Domu.new( "mx-1-cbv1", 512, 1, [ "br99", "br10" ], 5),
    Domu.new( "mx-1-cbv2", 512, 1, [ "br99", "br30" ], 5, "xen-2-cbv1" ),
    Domu.new( "proxy-1-abalone", 256, 1, [ "br99", "br812" ], 20, "xen-2-cbv1" ),
    Domu.new( "proxy-1-d2i", 256, 1, [ "br99" ], 20, "xen-2-cbv1" ),
    Domu.new( "proxy-1-latecis", 256, 1, [ "br99", "br811" ], 20, "xen-2-cbv1" ),
    Domu.new( "proxy-1-sigma", 256, 1, [ "br99", "br801" ], 20, "xen-2-cbv1" ),
    Domu.new( "proxy-1-sopap", 256, 1, [ "br99", "br98" ], 10, "xen-2-cbv1" ),
    Domu.new( "proxy-2-sigma", 256 , 1, [ "br99", "br802" ], 20, "xen-2-cbv1" ),
    Domu.new( "proxy-3-sigma", 256, 1, [ "br99", "br803" ], 20, "xen-2-cbv1" ),
    Domu.new( "proxy-1-villederennes", 256, 1, [ "br99", "br814" ], 20, "xen-2-cbv1" ),
    Domu.new( "paravirt-1-cbv1", 256, 1, [ "br99" ], 10, "xen-2-cbv1" ),
    Domu.new( "paravirt-2-cbv1", 256, 1, [ "br99" ], 10, "xen-2-cbv1" ),
    Domu.new( "paravirt-3-cbv1", 256, 1, [ "br99" ], 10, "xen-2-cbv1" ),
    Domu.new( "paravirt-4-cbv1", 256, 1, [ "br99" ], 10, "xen-2-cbv1" ),
    Domu.new( "proxy-test-grp-alpha", 256, 1, [ "br99", "br98" ], 10, "xen-2-cbv1" ),
    Domu.new( "voip-test-grp-alpha", 256, 1, [ "br99", "br20" ], 5, "xen-2-cbv1" ),
    Domu.new( "vserver-1-abalone", 4096, 4, [ "br805" ], 320, "xen-2-cbv1" ),
    Domu.new( "vserver-1-cacti-alphalink", 1024, 1, [ "br99", "br20" ], 80, "xen-2-cbv1" ),
    Domu.new( "vserver-1-jes", 4096, 2, [ "br99", "br808" ], 160, "xen-2-cbv1" ),
    Domu.new( "vserver-1-nostrepais", 1024, 1, [ "br99", "br809" ], 80, "xen-2-cbv1" ),
    Domu.new( "vserver-1-nvlasp", 2048, 2, [ "br99", "br810" ], 160, "xen-2-cbv1" ),
    Domu.new( "vserver-2-nvlasp", 2048, 2, [ "br99", "br816" ], 160, "xen-2-cbv1" ),
    Domu.new( "vserver-1-numlog", 1024, 1, [ "br99", "br813" ], 80, "xen-2-cbv1" ),
    Domu.new( "vserver-1-sigma", 1024, 1, [ "br804" ], 160, "xen-2-cbv1" ),
    Domu.new( "vserver-1-ucem", 256, 1, [ "br20" ], 11, "xen-2-cbv1" ),
    Domu.new( "vserver-2-qostelecom", 1024, 1, [ "br800" ], 160, "xen-2-cbv1" ),
    Domu.new( "vserver-1-qostelecom", 1024, 1, [ "br800" ], 160, "xen-2-cbv1" ),
    Domu.new( "www.alphalink.fr", 256, 1, [ "br10" ], 30, "xen-2-cbv1" ),
    Domu.new( "www.ucem.fr", 256, 1, [ "br20" ], 10, "xen-2-cbv1" ),
    Domu.new( "backup-aude-portzamparc", 512, 1, [ "xenbr0" ], 10, "xen-2-aude-portzamparc" ),
    Domu.new( "samba-aude-portzamparc", 512, 1, [ "xenbr0" ], 10, "xen-1-aude-portzamparc" ),
    Domu.new( "proxy-1-linksip", 512, 1, [ "br99", "br815" ], 40, "xen-2-cbv1" ),
]

# puts servers.to_yaml
File.open('tools/vserver/domu.yaml', 'w') do |file|
    file.puts(servers.to_yaml)
end
