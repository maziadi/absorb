class AdslIntercoEditor
  def initial_configuration(hash={})
    if !hash[:ip] or !hash[:peers]  or !hash[:ppp_local_ip]
      raise "ip, peers and ppp_local_ip are mandatory"
    end
    #create_iface :network => hash[:network], :vlan => hash[:vlan]
    create_pppd :ppp_local_ip => hash[:ppp_local_ip]
    create_l2tp hash
  end

  def create_l2tp(hash={})
    if !hash[:ip] or !hash[:peers]
      raise "ip and peers are mandatory"
    end
    @peers = hash[:peers]
    @ip = hash[:ip]
    erb = $root_dir + "/usr/share/lisos/erb/l2tp.erb"
    l2tp_config_file = $root_dir + "/etc/l2tp/l2tp.conf"
    @peers.each do |peer, secret|
      raise "You have to define password for your peer" if secret.nil?
    end
    do_erb(erb, l2tp_config_file)
    do_command("/etc/init.d/l2tp restart")
  end

  def create_pppd(hash={})
    if !hash[:ppp_local_ip]
      raise "ppp_local_ip is mandatory"
    end
    @ip_ppp = hash[:ppp_local_ip]
    erb = $root_dir + "/usr/share/lisos/erb/ppp_options.erb"
    ppp_config_file = $root_dir + "/etc/ppp/options"
    do_erb(erb, ppp_config_file)
  end

  def create_iface(hash = {})
    if !hash[:network] or !hash[:vlan]
      raise "network, vlan are mandatory"
    end

    # TODO : refactor static value for gw network
    l2tp_cbv1 = "217.15.80.32/29"
    l2tp_cbv2 = "217.15.88.32/29"

    iface = Iface::new "bond0.#{hash[:vlan]}"
    network, netmask, broadcast = Iface::calculate_range(hash[:network])
    address, gw_cbv1, gw_cbv2 = Iface::calculate_interco_param(network, broadcast)

    iface.options["address"]= address
    iface.options["netmask"]= netmask

    iface.options["lima_l2tp_cbv1"] = "network #{l2tp_cbv1} gw address #{gw_cbv1} type arp"
    iface.up << "ip route add #{l2tp_cbv2} via #{gw_cbv1} proto static metric 2 || true"
    iface.options["lima_l2tp_cbv2"] = "network #{l2tp_cbv2} gw address #{gw_cbv2} type arp"
    iface.up << "ip route add #{l2tp_cbv1} via #{gw_cbv2} proto static metric 2 || true"

    itf_editor =  InterfacesEditor::new #initialize augeas
    if itf_editor.existIface?(iface.name)
      STDERR.puts "IFace #{iface.name} already exist"
      itf_editor.save
      false
    else
      itf_editor.addIface(iface, "Vlan L2TP")
      itf_editor.save
      true
    end
  end
end


class TransitIntercoEditor < InterfacesEditor
  def create_interco(hash={})
    if !hash[:network] or !hash[:vlan]
      raise "network and vlan are mandatory"
    end

    private_addr = ["192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8", "169.254.0.0/16"]

    iface = Iface::new "bond0.#{hash[:vlan]}"
    network, netmask, broadcast = Iface::calculate_range(hash[:network])
    address, gw_cbv1, gw_cbv2 = Iface::calculate_interco_param(network, broadcast)

    iface.options["address"]= address
    iface.options["netmask"]= netmask

    iface.options["lima_transit"] = "network default gw address #{gw_cbv1} gw address #{gw_cbv2}"

    private_addr.each do |network|
      iface.up << "ip route add unreachable #{network} proto static || true"
      iface.down << "ip route del unreachable #{network} proto static || true"
    end
    addIface(iface, "Vlan Transit")
    save
  end
end


class SdslIntercoEditor < SdslEditor
  def initial_configuration(hash={})
    if !hash[:ip]  or !hash[:peers]
      raise "ip and peers are mandatory"
    end
    initial_configuration_gen("SDSL",hash)
  end
end



class VpnsslIntercoEditor < VpnsslEditor
  def initial_configuration(hash={})
    if !hash[:ip]  or !hash[:peers]
      raise "ip and peers are mandatory"
    end
    initial_configuration_gen("VPNSSL",hash)
  end
end 

