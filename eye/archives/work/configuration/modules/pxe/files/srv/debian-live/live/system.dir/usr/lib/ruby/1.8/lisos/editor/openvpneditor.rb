require 'lisos/editor/augeditor'

class OpenvpnEditor  < AugEditor
  def initialize
    super
    if @aug.match("/augeas/load/OpenVPN").size == 0
      @aug.transform :lens => "OpenVPN.lns", :incl => ["/etc/openvpn/*.conf","/etc/openvpn/*.ccd/*"]
      @aug.load!
    end
  end
  def update_server(data)
    do_command("/etc/init.d/openvpn stop #{data[:name]}")
    @aug.rm "/files/etc/openvpn/#{data[:name]}/*"
    create_server(data)
  end
  def create_server(data)
    path = "/files/etc/openvpn/#{data[:name]}.conf"
    client_conf_dir =  "/etc/openvpn/#{data[:name]}.ccd"
    FileUtils.mkdir_p "#{$root_dir}#{client_conf_dir}"
    @aug.set "#{path}/#comment",data[:comment] if data[:comment]
    @aug.set "#{path}/local",data[:local]
    @aug.set "#{path}/port",data[:port]
    @aug.set "#{path}/proto",data[:proto]
    @aug.set "#{path}/dev",data[:dev]
    @aug.set "#{path}/script-security","2"
    @aug.set "#{path}/up",data[:up]
    @aug.set "#{path}/server-bridge/address",data[:bridge_address]
    @aug.set "#{path}/server-bridge/netmask",data[:bridge_netmask]
    @aug.set "#{path}/server-bridge/start",data[:bridge_start]
    @aug.set "#{path}/server-bridge/end",data[:bridge_end]

    @aug.set "#{path}/client-config-dir",client_conf_dir
    @aug.set "#{path}/ccd-exclusive",nil
    @aug.set "#{path}/ca","/etc/openvpn/keys/ca.crt"
    @aug.set "#{path}/cert","/etc/openvpn/keys/vpnssl.crt"
    @aug.set "#{path}/key","/etc/openvpn/keys/vpnssl.key"
    @aug.set "#{path}/dh","/etc/openvpn/keys/dh1024.pem"
    @aug.set "#{path}/keepalive/ping","10"
    @aug.set "#{path}/keepalive/timeout","120"
    @aug.set "#{path}/comp-lzo",nil
    @aug.set "#{path}/user","nobody"
    @aug.set "#{path}/group","nogroup"
    @aug.set "#{path}/persist-key",nil
    @aug.set "#{path}/persist-tun",nil
    @aug.set "#{path}/verb","4"
    @aug.set "#{path}/mute","20"
    @aug.set "#{path}/crl-verify","/etc/openvpn/keys/crl.pem"
    save
    do_command("/etc/init.d/openvpn start #{data[:name]}")
  end
  def delete_server(data)
    # checker si account exist
    account = Dir.glob("#{$root_dir}/etc/openvpn/#{data[:name]}.ccd/*")
    if account.size > 0
      raise "Somes accounts exists, impossible to delete service #{data[:name]}"
    end
    do_command("/etc/init.d/openvpn stop #{data[:name]}")
    # delete
    FileUtils.rm_rf("#{$root_dir}/etc/openvpn/#{data[:name]}")
    FileUtils.rm("#{$root_dir}/etc/openvpn/#{data[:name]}.conf")
  end
  def create_server_account(data)
    path = "/etc/openvpn/#{data[:server_name]}.ccd"
    if !File::directory?("#{$root_dir}#{path}" )
      raise "VPN #{data[:server_name]} doesn't seem to be configure"
    end
    path_aug = "/files#{path}/#{data[:name]}"
    @aug.set "#{path_aug}/#comment",data[:comment]
    @aug.set "#{path_aug}/ifconfig-push/local",data[:ip_addr].to_s
    @aug.set "#{path_aug}/ifconfig-push/remote-netmask",data[:netmask].to_s

    if data[:routes]
      data[:routes].each do |route|
        if route == "0.0.0.0/0"
          @aug.set "#{path_aug}/push[last()+1]","redirect-gateway"
        else
          network, netmask, broadcast = Iface::calculate_range(route)
          @aug.set "#{path_aug}/push[last()+1]","route #{network} #{netmask}"
        end
      end
    end

    if data[:dns_servers]
      data[:dns_servers].each do |dns|
        @aug.set "#{path_aug}/push[last()+1]","dhcp-option DNS #{dns}"
      end
    end

    if data[:wins_servers]
      data[:wins_servers].each do |wins|
        @aug.set "#{path_aug}/push[last()+1]","dhcp-option WINS #{wins}"
      end
    end
    save
    data
  end
  def delete_server_account(data)
    name = "#{$root_dir}/etc/openvpn/#{data[:server_name]}.ccd/#{data[:name]}"
    unless File.file?(name) 
      raise "Account name #{data[:name]} doesn't exist"
    end
    FileUtils.rm(name)
    data
  end
end
