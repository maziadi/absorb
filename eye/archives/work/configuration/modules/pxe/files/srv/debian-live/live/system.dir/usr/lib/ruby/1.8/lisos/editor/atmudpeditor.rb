require 'lisos/editor/itfeditor'

class AtmudpEditor < InterfacesEditor
  def initialize
    super
    if @aug.match("/augeas/load/Atmudp").size == 0
      @aug.transform :lens => "Atmudp.lns", :incl => "/etc/network/atmudp"
      @aug.load!
    end
    @path_atmudp = "/files/etc/network/atmudp"
  end
  def add_itf_socket(hash={})
    restart_atmudp = true
    f = File.open("/proc/modules", "r")
    f.each do |line|
      restart_atmudp = false if line =~ /^.*atmudp.*$/
    end
    f.close
    # check if tap:96 exist, else add it
    if not @aug.match("#{@path_atmudp}/ITF/id[. = '96']").size > 0
      @aug.insert("#{@path_atmudp}/DAEMON[last]", "ITF", false)
      @aug.set("#{@path_atmudp}/#comment[last()+1]", "ITF tap")
      @aug.set("#{@path_atmudp}/ITF", "tap")
      @aug.set("#{@path_atmudp}/ITF/id", "96")
    end
    id  = hash[:id] ? hash[:id] : find_first_free_id("#{@path_atmudp}/ITF/id", 64)
    if hash[:comment]
      @aug.insert("#{@path_atmudp}/ITF[last()]", "#comment", false)
      @aug.insert("#{@path_atmudp}/#comment[.='']","ITF",false)
      @aug.set("#{@path_atmudp}/#comment[.='']", hash[:comment])
    else
      @aug.insert("#{@path_atmudp}/ITF[last()]", "ITF", false)
    end
    @aug.set("#{@path_atmudp}/ITF[last()]",    "socket")
    @aug.set("#{@path_atmudp}/ITF[last()]/id",     "#{id}")
    @aug.set("#{@path_atmudp}/ITF[last()]/ip",     "#{hash[:ip]}")
    @aug.set("#{@path_atmudp}/ITF[last()]/port",   "#{hash[:port]}")
    @aug.set("#{@path_atmudp}/ITF[last()]/daemon", "#{hash[:daemon_id]}")
    save
    if restart_atmudp
      do_command("/etc/init.d/atmudp restart")
    else
      do_command("atmudp-control add-itf-socket #{id} #{hash[:ip]} #{hash[:port]} #{hash[:daemon_id]}")
    end
  end

  def add_itf_visp(hash={})
    restart_atmudp = true
    f = File.open("/proc/modules", "r")
    f.each do |line|
      restart_atmudp = false if line =~ /^.*atmudp.*$/
    end
    f.close

    # check if tap:96 exist, else add it
    if not @aug.match("#{@path_atmudp}/ITF/id[. = '96']").size > 0
      @aug.insert("#{@path_atmudp}/DAEMON[last]", "ITF", false)
      @aug.set("#{@path_atmudp}/#comment[last()+1]", "ITF tap")
      @aug.set("#{@path_atmudp}/ITF", "tap")
      @aug.set("#{@path_atmudp}/ITF/id", "96")
    end

    daemon_id = @aug.get("#{@path_atmudp}/DAEMON/id[../ip='#{hash[:ip].split(":")[0]}']")
    raise "Cannot find daemon with ip #{hash[:ip]}" if daemon_id.nil?

    hash[:peers].each do |peer|
      tab = peer.split(",")
      ip_port = tab[0].split(":")
      tab.shift
      comment = tab.size > 0 ? tab.join(",") : nil
      ip = ip_port[0]
      port = ip_port[1] ? ip_port[1] : "2600"
      
      ipaddr, netmask, broadcast = Iface::calculate_range(ip)
      # use this variable for the first insertion
      first_ip = ipaddr

      while ipaddr <= broadcast
        id  = find_first_free_id("#{@path_atmudp}/ITF/id", 64)
        comment_itf = ipaddr == first_ip ? comment : nil
        add_itf_socket :id => id, :ip => ipaddr, :port => port, :daemon_id => daemon_id, :comment => comment_itf
        ipaddr += 1
      end
    end
  end

  def del_itf_socket(hash={})
    restart_atmudp = true
    f = File.open("/proc/modules", "r")
    f.each do |line|
      restart_atmudp = false if line =~ /^.*atmudp.*$/
    end
    f.close

    if @aug.match("/files/etc/network/atmudp/ROUTE/vcc/itf[.='#{hash[:id]}']").size > 0
      raise "Impossible to destroy itf, somes routes are used"
    end

    aug_path = "/files/etc/network/atmudp/ITF[id='#{hash[:id]}'][ip='#{hash[:ip]}'][port='#{hash[:port]}'][daemon='#{hash[:daemon_id]}']"
    comment_path = "/files/etc/network/atmudp/#comment[following-sibling::*[1][self::ITF[./id='#{hash[:id]}'][./ip='#{hash[:ip]}'][./port='#{hash[:port]}'][./daemon='#{hash[:daemon_id]}']]]"

    if @aug.match(aug_path).size > 0
      if @aug.match(comment_path).size > 0
        @aug.rm(comment_path)
      end
      @aug.rm(aug_path)
    end
    save

    if restart_atmudp
      do_command("/etc/init.d/atmudp restart")
    else
      do_command("atmudp-control add-itf-socket #{id} #{hash[:ip]} #{hash[:port]} #{hash[:daemon_id]}")
    end
  end

  def add_daemon(data)
    id = data[:id] ? data[:id] : find_first_free_id("#{@path_atmudp}/DAEMON/id") 
    ip = data[:ip] 
    port = data[:port] ? data[:port] : "2600"
    comment = data[:comment]
    restart_atmudp = true
    # check id
    if @aug.match("#{@path_atmudp}/DAEMON/id[.='#{id}']").size > 0
      raise "atmudp daemon id #{id} already use"
    end

    f = File.open("/proc/modules", "r")
    f.each do |line|
      restart_atmudp = false if line =~ /^.*atmudp.*$/
    end
    f.close

    unless @aug.match("#{@path_atmudp}/#comment[.='#{comment}']").size > 0
      if @aug.match("#{@path_atmudp}/DAEMON/id").size > 0
        @aug.insert("#{@path_atmudp}/DAEMON[last()]", "#comment", false)
        @aug.set("#{@path_atmudp}/#comment[.='']", "#{comment}")
        @aug.insert("#{@path_atmudp}/#comment[. = '#{comment}']", "DAEMON", false) 
        @aug.set("#{@path_atmudp}/DAEMON[last()]/id",   "#{id}")
        @aug.set("#{@path_atmudp}/DAEMON[last()]/ip",   "#{ip}")
        @aug.set("#{@path_atmudp}/DAEMON[last()]/port", "#{port}")
      else
        @aug.set("#{@path_atmudp}/#comment[last()+1]", "#{comment}")
        @aug.set("#{@path_atmudp}/DAEMON/id",   "#{id}")
        @aug.set("#{@path_atmudp}/DAEMON/ip",   "#{ip}")
        @aug.set("#{@path_atmudp}/DAEMON/port", "#{port}")
      end
    end
    save

    if restart_atmudp
      do_command("/etc/init.d/atmudp restart")
    else
      do_command("atmudp-control add-daemon #{id} #{ip} #{port}")
    end
    id
  end

  def add_route_visp(hash)
    ip_port, vp, vc = hash[:vcc].split("/")
    ip_port = ip_port.split(":")
    ip = ip_port[0]
    port = ip_port[1] ? ip_port[1] : "2600"

    itf_id = @aug.get("#{@path_atmudp}/ITF/id[../ip='#{ip}'][../port='#{port}']") or raise "false peer ip addr #{ip}"
    vc_id  = find_first_free_id("#{@path_atmudp}/ROUTE/vcc/vc[../itf = '96'][../vp = '#{hash[:table]}']")

    # check if vpcp or nas are already use is already use
    vcc1 = "[itf = '#{itf_id}'][vp = '#{vp}'][vc = '#{vc}']"
    if @aug.match("#{@path_atmudp}/ROUTE/*#{vcc1}").size > 0
      raise "The vcc #{itf_id}.#{vp}.#{vc} is already use"
    end

    ## add atmudp data
    if @aug.match("#{@path_atmudp}/ROUTE").size > 0 
      if @aug.match("#{@path_atmudp}/#comment[. = '#{hash[:comment]}']").size > 0 and hash[:type]
        raise "comment must be uniq"
      end
      tables = @aug.match("#{@path_atmudp}/ROUTE/vcc[itf='96']/vp").map do |t|
        @aug.get("#{t}").to_i
      end.sort.uniq

      # find after witch table insert data
      table_pos = tables.first
      tables.each do |t|
        table_pos = t if t.to_i <= hash[:table].to_i
      end

      vc_id_pos = nil

      vc_ids = @aug.match("#{@path_atmudp}/ROUTE/vcc[itf='96'][vp='#{table_pos}']").map do |v|
        @aug.get("#{v}/vc").to_i
      end.sort
      # recherche de la place du vc. on prend le dernier vc pour insérer après la position de la table (la position est toujours inférieure) sinon on recherche le bon emplacement dans la table
      if table_pos == hash[:table].to_i
        vc_id_pos = vc_ids.first
        vc_ids.each do |t|
          vc_id_pos = t if t.to_i <= vc_id.to_i
        end
      else
        vc_id_pos = vc_ids.last
      end


      if hash[:table].to_i >= table_pos.to_i
        position = "ROUTE[vcc/itf='96'][vcc[2]/vp='#{table_pos}'][vcc[2]/vc='#{vc_id_pos}']"
      else
        position = "ITF[last()]"
      end
      @aug.insert("#{@path_atmudp}/#{position}", "#comment", false)
      @aug.set("#{@path_atmudp}/#comment[.='']", hash[:comment])
      @aug.insert("#{@path_atmudp}/#comment[. = '#{hash[:comment]}']", "ROUTE", false)
      @aug.set("#{@path_atmudp}/ROUTE[count(vcc) = 0]/vcc/itf", "#{itf_id}")
      @aug.set("#{@path_atmudp}/ROUTE/vcc[count(vp) = 0]/vp",  "#{vp}")
      @aug.set("#{@path_atmudp}/ROUTE/vcc[count(vc) = 0]/vc",  "#{vc}")
      @aug.set("#{@path_atmudp}/ROUTE[count(vcc) = 1]/vcc[2]/itf", "96")
      @aug.set("#{@path_atmudp}/ROUTE/vcc[count(vp) = 0]/vp",  "#{hash[:table]}")
      @aug.set("#{@path_atmudp}/ROUTE/vcc[count(vc) = 0]/vc",  "#{vc_id}")
    else
      @aug.insert("#{@path_atmudp}/ITF[last()]", "#comment", false)
      @aug.set("#{@path_atmudp}/#comment[.='']", hash[:comment])
      @aug.insert("#{@path_atmudp}/#comment[. = '#{hash[:comment]}']", "ROUTE", false)
      @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[1]/itf", "#{itf_id}")
      @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[1]/vp",  "#{vp}")
      @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[1]/vc",  "#{vc}")
      @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[2]/itf", "96")
      @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[2]/vp",  "#{hash[:table]}")
      @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[2]/vc",  "#{vc_id}")
    end
    route = "#{itf_id}.#{vp}.#{vc}:96.#{hash[:table]}.#{vc_id}"
    save

    do_command("/etc/init.d/atmudp start #{route}")
    # return nas name
    "nas#{sprintf '%.3d', hash[:table].to_i}#{sprintf '%.3d', vc_id}"
  end

  def free_vcc?(itf,vp,vc)
    @aug.match("/files/etc/network/atmudp/ROUTE/vcc[./itf='#{itf}'][./vp='#{vp}'][./vc='#{vc}']").size == 0
  end

  def add_route(data)
    # :vccs => [ { :id , :vp :vc },{ :id , :vp :vc }] :comment
    test1 = @aug.match "/files/etc/network/atmudp/ROUTE/vcc[./itf='#{data[:vccs][0][:id]}'][./vp='#{data[:vccs][0][:vp]}'][./vc='#{data[:vccs][0][:vc]}']"
    test2 = @aug.match "/files/etc/network/atmudp/ROUTE/vcc[./itf='#{data[:vccs][1][:id]}'][./vp='#{data[:vccs][1][:vp]}'][./vc='#{data[:vccs][1][:vc]}']"
    raise "itf/vp/vc : #{data[:vccs][0][:id]}/#{data[:vccs][0][:vp]}/#{data[:vccs][0][:vc]} is already use" if test1.size > 0
    raise "itf/vp/vc : #{data[:vccs][1][:id]}/#{data[:vccs][1][:vp]}/#{data[:vccs][1][:vc]} is already use" if test2.size > 0
    @aug.set("#{@path_atmudp}/#comment[last()+1]", data[:comment])
    @aug.set("#{@path_atmudp}/ROUTE[last()+1]/vcc[1]/itf", "#{data[:vccs][0][:id]}")
    @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[1]/vp",  "#{data[:vccs][0][:vp]}")
    @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[1]/vc",  "#{data[:vccs][0][:vc]}")
    @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[2]/itf", "#{data[:vccs][1][:id]}")
    @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[2]/vp",  "#{data[:vccs][1][:vp]}")
    @aug.set("#{@path_atmudp}/ROUTE[last()]/vcc[2]/vc",  "#{data[:vccs][1][:vc]}")
    route = "#{data[:vccs][0][:id]}.#{data[:vccs][0][:vp]}.#{data[:vccs][0][:vc]}:#{data[:vccs][1][:id]}.#{data[:vccs][1][:vp]}.#{data[:vccs][1][:vc]}"
    save
    do_command("/etc/init.d/atmudp start #{route}")
  end

  def del_route(data)
    
    local_itf  = data[:vccs][0][:id]
    local_vp   = data[:vccs][0][:vp]
    local_vc   = data[:vccs][0][:vc]
    remote_itf = data[:vccs][1][:id]
    remote_vp  = data[:vccs][1][:vp]
    remote_vc  = data[:vccs][1][:vc]

    @path_atmudp         = "/files/etc/network/atmudp"
    route_path    = "#{@path_atmudp}/ROUTE[vcc/itf='#{local_itf}'][vcc/vp='#{local_vp}'][vcc/vc='#{local_vc}']"
    comment_path  = "#{@path_atmudp}/#comment[following-sibling::*[1][self::ROUTE/vcc/itf='#{local_itf}'][self::ROUTE/vcc/vp='#{local_vp}'][self::ROUTE/vcc/vc='#{local_vc}']]"

    if @aug.match(route_path)
      # get route information in /etc/network/atmudp
      # build route information
      match1 = @aug.match("/#{@path_atmudp}/ROUTE/vcc[itf='#{local_itf}'][vp='#{local_vp}'][vc='#{local_vc}']").first
      match2 = @aug.match("/#{@path_atmudp}/ROUTE/vcc[itf='#{remote_itf}'][vp='#{remote_vp}'][vc='#{remote_vc}']").first

      if !match1 or !match2 
        raise "no route match your demand"
      end

      match1.slice!(-3,3)
      match2.slice!(-3,3)
      if match1 == match2
        remote = "#{local_itf}.#{local_vp}.#{local_vc}"
        locale = "#{remote_itf}.#{remote_vp}.#{remote_vc}"
        if ! (id = @aug.get(match1 + "[1]/itf")).nil?
          route = "#{remote}:#{locale}"
        else
          route = "#{locale}:#{remote}"
        end
      end
      # stop route
      do_command("/etc/init.d/atmudp stop #{route}")

      # clean config file
      if @aug.match(comment_path).size > 0
        @aug.rm(comment_path)
      end

      if @aug.match(route_path).size == 1
        @aug.rm(route_path)
      end
      save
    else
      raise "no route match your demand"
    end

  end

  def del_route_visp(table,vc_id)
    @path_atmudp         = "/files/etc/network/atmudp"
    route_path    = "#{@path_atmudp}/ROUTE[vcc[2]/vp='#{table}'][vcc[2]/vc='#{vc_id}']"
    comment_path  = "#{@path_atmudp}/#comment[following-sibling::*[1][self::ROUTE/vcc[2]/vp='#{table}'][self::ROUTE/vcc[2]/vc='#{vc_id}']]"
    if @aug.match("#{@path_atmudp}/ROUTE/vcc[./vp='#{table}'][./vc='#{vc_id}']")
      # get route information in /etc/network/atmudp
      itf_id = @aug.get("#{route_path}/vcc[1]/itf")
      vp = @aug.get("#{route_path}/vcc[1]/vp")
      vc = @aug.get("#{route_path}/vcc[1]/vc")
      route = "#{itf_id}.#{vp}.#{vc}:96.#{table}.#{vc_id}"

      # stop route
      do_command("/etc/init.d/atmudp stop #{route}")

      # clean config file
      if @aug.match(comment_path).size > 0
        @aug.rm(comment_path)
      end

      @aug.rm(route_path)
      save
    else
      raise "no route match your demand"
    end

  end


  def initial_configuration_gen(name,hash)
    # Configure atmudp
    ip_port = hash[:ip].split(":")
    ip = ip_port[0]
    port = ip_port[1] ? ip_port[1] : "2600"
    daemon_id = add_daemon :ip => ip, :port => port, :comment => name
    add_itf_visp(hash)
    save
  end

  def get_id_itf(ip,port="2600")
    @aug.get("#{@path_atmudp}/ITF/id[../ip='#{ip}'][../port='#{port}']")
  end


  def check_free_vp_vc(itf,vp,vc)
    @aug.match("#{@path_atmudp}/ROUTE/vcc[./itf='#{itf}'][./vp='#{vp}'][./vc='#{vc}']").size == 0
  end

  def create(hash={})
    if !hash[:vccs]
      raise "vccs and ip (if not bridge) are mandatory"
    end

    @path = "/files/etc/network/interfaces"
    iface_name = nil

    # table is used to create the interface name for bridge and bond.
    table = RoutingTableEditor.new.get_table(hash[:table])


    if hash[:type] and hash[:vccs].size > 1


      error_check = []

      hash[:vccs].each do |value|
        ip_port, vp, vc = value.split("/")
        ip_port = ip_port.split(":")
        ip = ip_port[0]
        port = ip_port[1] ? ip_port[1] : "2600"
        id_itf = get_id_itf(ip,port)
        if !id_itf
          error_check << "ITF #{ip}:#{port} not found"
        else
          error_check << "itf/vc/vp #{ip}:#{port}/#{vp}/#{vc} already configured" if !check_free_vp_vc(id_itf,vp,vc)
        end
      end
      if error_check.size > 0
        raise error_check.join(", ")
      end


      nas = []
      count = hash[:vccs].size
      id = 1
      hash[:vccs].each do |value|
        data = {}
        data[:vcc] = value
        data[:table] = table
        data[:comment] = hash[:comment] + " #{id}/#{count}"
        data[:type] = true
        nas << add_route_visp(data)
        id += 1
      end
      
      itf = hash[:type]

      used_itf = @aug.match("#{@path}/iface[. =~ regexp('#{itf}#{sprintf("%.3d", table)}[0-9]{3}')]").map do |value|
        @aug.get(value)
      end.sort

      if used_itf.size > 0
        iface_name = "#{itf}#{sprintf("%.6d", (used_itf.last.gsub(/#{itf}/, '').to_i + 1))}"
      else
        iface_name = "#{itf}#{sprintf("%.3d", table)}001"
      end
    elsif hash[:vccs].size == 1 and !hash[:type]
      data = {}
      data[:vcc] =  hash[:vccs].first
      data[:table] = table
      data[:type] = false
      data[:comment] = hash[:comment]
      iface_name = add_route_visp(data)
      save
    else
      raise "Your configuration is not correct. For bonding or bridging you need two or more vcc"
    end

    iface = Iface.new(iface_name)
    if itf == "br"
      iface.options["bridge_ports"]   = nas.join(" ")
      iface.options["bridge_maxwait"] = "0"
    end
    if hash[:ip]
      network, netmask, broadcast = Iface::calculate_range(hash[:ip])
      arp_target = hash[:arp_target] ? hash[:arp_target] : (broadcast - 1)
      # options for bonding and bridging
      if itf == "bond"
        iface.options["arp_ip_target"] = arp_target
        iface.options["arp_interval"]  = "200"
        iface.options["mode"]          = "BALANCE-RR"
        iface.options["ifaces"]        = nas.join(" ")
      end
      iface.options["address"] = hash[:ip].split("/")[0]
      iface.options["netmask"] = netmask
      iface.options["isolate"] = table if table != "254"
    else
      iface.method = "manual"
    end
    

    if hash[:ip] and hash[:routes]
      routes = {}
      hash[:routes].each do |data|
        routes[data.split(":")[0]] = data.split(":")[1]
      end

      routes.each do |net, gw|
        if table == "254"
          iface.up << "ip route add #{net} via #{gw} dev #{iface_name} || true" 
        else
          iface.up << "ip route add table #{table} #{net} via #{gw} dev #{iface_name} || true" 
        end
      end
    end

    addIface(iface, hash[:comment])
    save
  end

  def delete(name)
    @path = "/files/etc/network/interfaces"
    if !name
      raise "iface name is mandatory"
    end
    if existIface?(name)
      reals_ifaces = @aug.get("#{@path}/iface[. = '#{name}']/ifaces")
      delIface(name)
      if reals_ifaces
        reals_ifaces.split(" ").each do |iface|
          vp = iface.gsub(/nas|[0-9]{3}$/, '').to_i
          vc = iface.gsub(/nas[0-9]{3}/, '').to_i
          del_route_visp(vp, vc)
        end
      else
        vp = name.gsub(/nas|[0-9]{3}$/, '').to_i
        vc = name.gsub(/nas[0-9]{3}/, '').to_i
        del_route_visp(vp, vc)
      end
    else
      raise "Iface #{name} not found"
    end
  end
end

class SdslEditor < AtmudpEditor
end

class VpnsslEditor < AtmudpEditor
end

