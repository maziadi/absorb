require 'lisos/editor/augeditor'

class AdslEditor < AugEditor
  def initialize
    super
    if @aug.match("/augeas/load/Profile_ppp").size == 0
      @aug.transform :lens => "Profile_ppp.lns", :incl => "/etc/ppp/profiles/*"
      @aug.load!
    end
    if @aug.match("/augeas/load/Freeradius_users").size == 0
      @aug.transform :lens => "Freeradius_users.lns", :incl => "/etc/freeradius/users"
      @aug.load!
    end
  end

  def create(hash)
    if !hash.include?(:login) or !hash.include?(:table) or !hash.include?(:secret) or !hash.include?(:ip)
      raise "login, table, secret and ip are mandatory"
    end
    table = RoutingTableEditor.new.get_table(hash[:table])
    add_radius(hash[:login], hash[:secret], hash[:ip])
    add_profil(hash[:login], table, hash[:name], hash[:routes])
  end

  def modify(hash)
    if !hash.include?(:login) or !hash.include?(:table) or !hash.include?(:secret) or !hash.include?(:ip)
      raise "login, table, secret and ip are mandatory"
    end
    #TODO
  end
  def delete(login)
    del_profil(login)
    del_radius(login)
  end


  def get_all_logins
    @aug.match("/files/etc/freeradius/users/user").map{|value| @aug.get(value) }
  end

  #TODO : refactor this
  private
  
  def add_profil(login, table, name, routes = nil)
    
    # check if file already exist
    raise "profile ppp for #{login} already exist" if @aug.match("/files/etc/ppp/profiles/#{login}").size > 0

    # find name of the ppp if not define
    if name
      if @aug.match("/files/etc/ppp/profiles/*/name[.='#{name}']").size > 0
        raise "This iface name is already use"
      else
        ppp = name
      end
    else
      full_table = sprintf "%.3d", table
      values = []
      indice = 1
      @aug.match("/files/etc/ppp/profiles/*/name[. =~ regexp(\"ppp#{full_table}.*\")]").collect do |line|
        if line
          values << @aug.get(line)[-3,3].to_i
        end
      end.compact.sort

      # find a free indice
      values.each do |value|
        if indice == value
          indice += 1
        else
          break
        end
      end

      indice = sprintf "%.3d", indice


      ppp = "ppp" + full_table.to_s + indice.to_s
    end

		@aug.set("/files/etc/ppp/profiles/#{login}/name",ppp)

    if table != "254" 
		  @aug.set("/files/etc/ppp/profiles/#{login}/isolate",table.to_s)
    end

    if routes
      routes.each do |route|
        if table.to_s == "254"
          cmd = "ip route add #{route} dev #{ppp}"
        else
          cmd = "ip route add table #{table.to_s} #{route} dev #{ppp}"
        end
		    @aug.set("/files/etc/ppp/profiles/#{login}/up[last+1]", cmd)
      end
    end

    save
  end

  def del_profil(login)
    if @aug.match("/files/etc/ppp/profiles/*[label()='#{login}']").size > 0
      @aug.rm("/files/etc/ppp/profiles/*[label()='#{login}']")
      save
    else
      raise "The profile #{login} doesn't exist"
    end
  end

  def add_radius(login, secret, ip)
    
    raise "login #{login} already defined" if get_all_logins.include?(login)
    
    @aug.set("/files/etc/freeradius/users/user[last()+1]",login)
    @aug.set("/files/etc/freeradius/users/user[last()]/Auth-Type","Local")
    @aug.set("/files/etc/freeradius/users/user[last()]/User-Password",secret)
    @aug.set("/files/etc/freeradius/users/user[last()]/Framed-IP-Address",ip)
    @aug.set("/files/etc/freeradius/users/user[last()]/Fall-Through","No")
    save

    # reload freeradius
    do_command("kill -HUP $(pidof freeradius)")
  end

  def del_radius(login)
    if @aug.match("/files/etc/freeradius/users/user[.='#{login}']").size > 0
     @aug.rm("/files/etc/freeradius/users/user[.='#{login}']")
     save
     # reload freeradius
     # TODO destroy ppp
     do_command("kill -HUP $(pidof freeradius)")
    else
      raise "The login #{login} doesn't exist"
    end
  end
end
