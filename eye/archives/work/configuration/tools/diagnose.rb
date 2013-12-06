#!/usr/bin/env ruby

require 'rubygems'
require 'graphviz_r'

class Host
    attr_reader :name, :interfaces, :routes
         
    def initialize(name, interfaces, routes)
        @name, @interfaces, @routes = name, interfaces, routes
    end

    def find_route_by_interface(name)
       #TODO 
    end
end

class Interface
    attr_reader :name, :addresses

    def initialize(name, addresses = [])
        @name, @addresses = name, addresses
    end

end

class Route
    attr_reader :net, :dev, :via, :src

    def initialize(net, dev, via, src)
        @net, @dev, @via, @src = net, dev, via, src
    end
end

class RemoteHost
    def initialize(url, user = 'root')
       @url, @user = url, user 
    end

    def sh(cmd)
       `ssh #{@user}@#{@url} '#{cmd}'` 
    end

    def self::describe(hostname)
        remote = RemoteHost::new(hostname)
        name = remote.sh("hostname").chomp
        Host::new(name, remote.get_interfaces, remote.get_routes)
    end

    def get_space
        lines = sh("df -k").split("\n")
        lines.shift
        lines.each do |line|
            line =~ // 
        end
    end

    def get_routes
        lines = sh("ip route show").split("\n")
        lines.collect do |line|
            # 172.16.3.0/24 via x.y.z dev eth1  proto kernel  scope link  src 172.16.3.251
            line = line.split(/ +/)
            net = line.shift
            via, dev, src = nil, nil, nil
            while line.size > 0
                case line.shift
                when "via": via = line.shift
                when "dev": dev = line.shift
                when "src": src = line.shift
                end
            end
            Route::new(net, dev, via, src)
        end
    end

    def get_interfaces
        lines = sh("ip address show").split("\n")
        devices = {}
        device = nil
        lines.each do |line|
            case line
            when /^[0-9]+: ([^:]+):/:
                device = $1
            when /[ ]+link\//:
            when /[ ]+inet ([^ ]+)/:
               (devices[device] ||= Interface::new(device)).addresses << $1 
            else
                puts "Unrecogized line '#{line}' was ignored."
            end
        end

        devices.values
    end
end

def esc_addr(str)
    str.split('/').first.gsub(/[.\/]/, '_')
end

host = RemoteHost::describe(ARGV[0])
puts host.inspect

gvr = GraphvizR.new 'host'
gvr.graph[:rankdir => 'LR']
gvr.node[:shape => :record, :fontname => 'helvetica']
gvr.host[:label => host.name]
interface_names = host.interfaces.collect { |interface|
    interface_name = interface.name.to_sym
    gvr[interface_name][:label => "{{" + interface.addresses.collect { |a| "<f_#{esc_addr(a)}> #{a}" }.join('|') + "}|<f_#{interface.name}> #{interface.name}}"] 
    (gvr.host >> gvr[interface_name])[:shape => 'none']
    interface_name
}
#gvr.rank(:same, interface_names)
route_names = host.routes.collect { |route|
    route_name = "route_" + route.net.gsub(/[\/.]/, '_')
    gvr[route_name][:label => route.net] 
    if route.via
        via_name = "via_" + route.via.gsub(/[\/.]/, '_')
        gvr[via_name][:label => route.via]
        (gvr[route_name] >> gvr[via_name])[:label => 'via', :fontname => 'helvetica', :shape => 'vee']
    end
    if route.src
        (gvr[route.dev.to_sym, "f_#{esc_addr(route.src)}".to_sym] >> gvr[route_name])[:shape => 'crow']
    elsif route.dev
        (gvr[route.dev.to_sym, "f_#{route.dev}".to_sym] >> gvr[route_name])[:shape => 'vee']
    end
    route_name
}

#gvr.rank(:same, route_names)
puts gvr.to_dot
File::open('/tmp/toto.png', 'w') { |f| f.write(gvr.data) }
File::open('/tmp/toto.svg', 'w') { |f| f.write(gvr.data(format = 'svg')) }
