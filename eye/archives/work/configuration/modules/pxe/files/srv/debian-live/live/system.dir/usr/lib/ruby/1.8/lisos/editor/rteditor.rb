require 'lisos/editor/augeditor'
class RoutingTableEditor < AugEditor
  def initialize
    super
    if @aug.match("/augeas/load/Rt_tables").size == 0
      @aug.transform :lens => "Rt_tables.lns", :incl => "/etc/iproute2/rt_tables"
      @aug.load!
    end
  end

  def get_table(arg)
    id = nil
    if arg.to_s =~ /^\d+$/
      id = arg.to_i
    else
      id = get_id_table(arg)
    end
    raise "Table #{arg} not found" if not id
    id
  end

  def get_id_table(name)
    values = @aug.match("/files/etc/iproute2/rt_tables/*[.='#{name}']")
    values.empty? ? nil : values[0].split("/").last
  end
  def get_name_table(id)
    @aug.get("/files/etc/iproute2/rt_tables/#{id}")
  end
    

  def add_table(table, id = nil)
    path = "/files/etc/iproute2/rt_tables"
    raise "table #{table} is already use" if get_id_table(table)
    raise "id #{id} is already use" if id and get_name_table(id)

    # get used id (delete reserved values)
    id_used = @aug.match("/files/etc/iproute2/rt_tables/*").collect do |line|
      nb = line.split("/").last
      nb !~ /#comment/ ? nb.to_i : nil
    end.compact.sort - [0, 253, 254, 255]

    # delete exemple comment if exist
    if @aug.match("#{path}/#comment[.=~ regexp('.*inr.ruhep.*')]")
      @aug.rm("#{path}/#comment[.=~ regexp('.*inr.ruhep.*')]")
    end

    if id.nil?
      id = (Array(1..253) - id_used).first
    end

    id_used << id.to_i
    id_used.sort!
    index = id_used.index id.to_i
    max = id_used.last == id.to_i ? nil : id_used.at(index + 1)
    min = id_used.first == id.to_i ? nil : id_used.at(index - 1)


    if min
      @aug.insert("#{path}/#{min}", id.to_s, false)
    elsif max
      @aug.insert("#{path}/#{max}", id.to_s, true)
    end
    @aug.set("#{path}/#{id}", table)


    save
    id
  end
  def del_table(value,id=nil)
    if id.nil?
      @aug.rm("/files/etc/iproute2/rt_tables/*[.='#{value}']")
    else
      @aug.rm("/files/etc/iproute2/rt_tables/'#{id}'[.='#{value}']")
    end
    save
  end
end
