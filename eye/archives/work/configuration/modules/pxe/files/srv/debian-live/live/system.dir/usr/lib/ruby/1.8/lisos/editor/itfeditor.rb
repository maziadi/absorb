require 'lisos/editor/augeditor'
require 'lisos/editor/common'

class InterfacesEditor < AugEditor
  def initialize
    super
    if @aug.match("/augeas/load/Interfaces").size == 0
      @aug.transform :lens => "Interfaces.lns", :incl => "/etc/network/interfaces"
      @aug.load!
    end
  end
  attr_accessor :aug
	def addIface(iface,comment=nil)
    raise "iface #{iface.name} is already configured" if existIface?(iface.name)
    @path = "/files/etc/network/interfaces"
    type = iface.name.gsub(/[0-9]/, '')
    table = sprintf "%.3d", iface.options["isolate"] 

    if @aug.match("#{@path}/iface[. =~ regexp('#{type}#{table}.*')]").size > 0
      use_tables = @aug.match("#{@path}/iface[. =~ regexp('#{type}#{table}.*')]").map do |t|
        @aug.get(t).gsub(/#{type}/, '')
      end.sort.uniq
      position = "#{type}#{use_tables.last}"
      @aug.insert("#{@path}/iface[. = '#{position}']", '#comment', false)
      @aug.set("#{@path}/#comment[.='']", "#{comment}")
      @aug.insert("#{@path}/#comment[. = '#{comment}']", "auto", false)
      @aug.set("#{@path}/auto[count(*) = 0]/1", iface.name)
      @aug.insert("#{@path}/auto[./1 = '#{iface.name}']", "iface", false)
      @aug.set("#{@path}/iface[count(*) =0]", iface.name)
		  setIfaceOptions(iface)
    else
		  @aug.set("/files/etc/network/interfaces/#comment[last()+1]",comment) if ! comment.nil?
		  @aug.set("/files/etc/network/interfaces/auto[last()+1]/1",iface.name) #we add options at the end
		  @aug.set("/files/etc/network/interfaces/iface[last()+1]",iface.name) #we add options at the end
		  setIfaceOptions(iface)
    end
    save
    do_command("ifup #{iface.name}")
	end
  def delIface(name)
    do_command("ifdown #{name}")
    @aug.rm("/files/etc/network/interfaces/#comment[following-sibling::*[1][self::auto/1='#{name}']]")
    @aug.rm("/files/etc/network/interfaces/iface[.='#{name}']")
    @aug.rm("/files/etc/network/interfaces/auto/*[.='#{name}']")
    @aug.rm("/files/etc/network/interfaces/auto[count(./*)=0]")
    save
  end
  def existIface?(name)
    @aug.match("/files/etc/network/interfaces/iface[.='#{name}']").size > 0
  end
	def setIfaceOptions(iface)
		@aug.set("/files/etc/network/interfaces/*[self::iface='#{iface.name}']/family",iface.family)
		@aug.set("/files/etc/network/interfaces/*[self::iface='#{iface.name}']/method",iface.method)
		if ! iface.options.nil?
      temp_options = iface.options.clone # we try to not delete values options
      ["network","address","netmask","broadcast","gateway"].each{|opt_name|
        opt_value = temp_options.delete(opt_name)
        aug.set("/files/etc/network/interfaces/*[self::iface='#{iface.name}']/#{opt_name}",opt_value.to_s) if !opt_value.nil?
      }
			temp_options.each { |opt_name,opt_value|
				@aug.set("/files/etc/network/interfaces/*[self::iface='#{iface.name}']/#{opt_name}",opt_value.to_s)
			}
		end
    [:pre_up,:up,:post_up,:pre_down,:down,:post_down].each do |state|
      tab = iface.send state
      tab.each{|value|
				@aug.set("/files/etc/network/interfaces/*[self::iface='#{iface.name}']/#{state.to_s.gsub("_","-")}[last()+1]",value.to_s)
      }
    end
	end
  def getOption(iface,opt)
		@aug.get("/files/etc/network/interfaces/*[self::iface='#{iface}']/#{opt}")
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
  def create_interco(hash)
    iface = Iface::new "bond0.#{hash[:vlan]}"
    iface.ip hash[:ip]

    if hash[:gateway].size != 2
      raise "You can have only 2 gateway"
    end

    gw1 = hash[:gateway][0]
    ip1 = gw1[:ip]
    name1 = gw1[:name] ? gw1[:name] : gw1[:ip]
    iface.options["lima_#{name1}"] = "network #{gw1[:network].join ","} gw address #{ip1}"

    gw2 = hash[:gateway][1]
    name2 = gw2[:name] ? gw2[:name] : gw2[:ip]
    ip2 = gw2[:ip]
    iface.options["lima_#{name2}"] = "network #{gw2[:network].join ","} gw address #{ip2}"
    
    gw1[:network].each{|peer|
      iface.up << "ip route add #{peer} via #{ip2}  proto static metric 2 || true"
    }

    gw2[:network].each{|peer|
      iface.up << "ip route add #{peer} via #{ip1}  proto static metric 2 || true"
    }

    addIface(iface, hash[:comment])

  end
end
