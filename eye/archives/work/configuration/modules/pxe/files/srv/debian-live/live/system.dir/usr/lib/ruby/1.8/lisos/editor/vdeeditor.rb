class VdeSwitchEditor < InterfacesEditor
  def create_server(hash={})
    if !hash[:name] or !hash[:ip]
      raise "name and ip are mandatory"
    end

    table = RoutingTableEditor.new.get_table(hash[:table]) if hash[:table]
    raise "vde_switch #{hash[:name]} already exist" if search_vde_switch_names.include?(hash[:name])
    hash[:iface] = hash[:name] + ( table ? table : "254") if !hash[:iface]
    raise "iface #{hash[:iface]} already exist" if existIface?(hash[:iface])

    augi = Iface::new hash[:iface]
    augi.ip hash[:ip]
    augi.options["vde-switch-server"] = "name #{hash[:name]}"
    augi.options["isolate"] = table if table

    addIface(augi)
    save
  end
  #TODO
  def modify_server(hash={})
  end
  
  def delete_server(hash={})
    if !hash[:name] or !hash[:iface] 
      raise "name and iface mandatory"
    end
    raise "You must delete all interface of vde_switch before" if search_vde_itf(hash[:name]).size > 0
    raise "Iface #{hash[:iface]} not found" if !existIface?(hash[:iface])
    delIface(hash[:iface])
    save
  end

  def add_interface(hash = {})
    hash[:gw] = true if ! hash.include?(:gw)
    if !hash[:name] or !hash[:ip] or !hash[:table]
      raise "name and ip are mandatory"
    end
    table = RoutingTableEditor.new.get_table(hash[:table])
    hash[:iface] = hash[:name] + table.to_s if !hash[:iface]

    res = search_vde_switch(hash[:name])
    if res.size == 0
      raise "vde_switch #{hash[:name]} not found"
    else
      raise "Iface #{hash[:iface]} already exist" if existIface?(hash[:iface])
      isolate = getOption(res.first,"isolate")
      vde_opt = "name transit"
      vde_opt += " force-neigh #{res.first}" if isolate.nil? or isolate == "254"
      vde_opt += " port #{hash[:port]}" if hash[:port]
      itf = Iface::new hash[:iface]
      itf.ip hash[:ip]
      itf.options["isolate"] = table
      itf.options["vde-switch"] = vde_opt
      itf.options["isolate_gateway"] = (hash[:ip_gateway] ? hash[:ip_gateway] : getOption(res.first,"address")) if hash[:gw]
      if hash[:route]
        hash[:route].each do |net, gw|
          if hash[:table] == "254"
            itf.up << "ip route add #{net} via #{gw} dev #{hash[:iface]} || true"
          else
            itf.up << "ip route add table #{hash[:table]} #{net} via #{gw} dev #{hash[:iface]} || true"
          end
        end
      end

      addIface(itf)
      save
    end
  end
  #TODO
  def modify_interface(hash={})
  end

  def delete_interface(name)
    raise "Iface #{name} not found" if !existIface?(name)
    delIface(name)
    save
  end

  def search_vde_switch_names
    @aug.match("/files/etc/network/interfaces/*/vde-switch-server").map{|value|
      @aug.get(value)[/name (\S+)/,1]
    }
  end
  def search_vde_switch(name)
    @aug.match("/files/etc/network/interfaces/iface[./vde-switch-server=~regexp('(.* )?name #{name}( .*)?')]").map{|value|
      @aug.get(value)
    }
  end
  def search_vde_itf(name)
    @aug.match("/files/etc/network/interfaces/iface[./vde-switch=~regexp('(.* )?name #{name}( .*)?')]").map{|value|
      @aug.get(value)
    }
  end
end
