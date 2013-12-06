require 'erb'
require 'ipaddr'
require 'lisos/editor'
require 'open3'

class IPAddr
  def +(nb)
    IPAddr::new(@addr + nb, Socket::AF_INET)
  end
  def -(nb)
    IPAddr::new(@addr - nb, Socket::AF_INET)
  end
end

class Iface
  attr_accessor :name,:family,:method,:options,:pre_up,:up,:post_up,:pre_down,:down,:post_down
  def initialize(new_name,new_family = "inet" ,new_method = "static")
    @name = new_name
    @family = new_family
    @method = new_method
    @options = {}
    @pre_up = []
    @up = []
    @post_up = []
    @post_down = []
    @down = []
    @pre_down = []
  end
  def ip(addr)
    @options["address"] = addr.split("/")[0]
    network, netmask, broadcast = Iface::calculate_range(addr)
    @options["netmask"] = netmask
  end
  def self.calculate_range(network_addr)
    network = IPAddr.new(network_addr)
    netmask = IPAddr.new("255.255.255.255/#{network_addr.split("/")[1]}")
    broadcast = network|~netmask
    [network, netmask, broadcast]
  end
  def self.calculate_interco_param(network, broadcast)
    gw_cbv1 = network + 1
    gw_cbv2 = network + 2
    address = broadcast - 1
    [address, gw_cbv1, gw_cbv2]
  end
end

def do_erb(erb, file)
  # test if somebody edit the destination.
  temp_file = "#{File.dirname file}.#{File.basename file}.swp"

  if File.exists?(temp_file)
    raise "The file is already open by somebody, #{temp_file} exist"
  end

  # build the file
  template = ERB::new(File::new(erb).readlines.join(""), 0, "%<>")
  File::open(file, "w") do |f|
    f.flock(File::LOCK_EX)
    f.write(template.result(binding))
    f.flock(File::LOCK_UN)
  end
end
def do_command(cmd)
    if $no_start.nil?
      Open3.popen3(cmd) do |stdin, stdout, stderr| 
        err = stderr.readlines
        if err.size != 0
          if $raise_on_error
            raise "error on #{cmd} : \n#{err}"
          else
            warn "error on #{cmd} : \n#{err}"
          end
          $do_command_error = true
        end
      end
    end
end

class ValidateCmd
  Opt = Struct::new(:value,:typo,:opt,:mandatory)
  IP = "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
  def initialize
    @str_error = []
    @opts = []
  end
  def val(value,typo,opt,mandatory)
    @opts << Opt::new(value,typo,opt,mandatory)
  end
  def validate_word(str)
    str =~ /^\w+$/ ? true : false
  end

  def validate_network(str)
    str =~ /^#{IP}(\/(3[0-2]|[1-2][0-9]|[0-9]))?$/ ? true : false
  end

  def validate_ip(str)
    str =~ /^#{IP}$/ ? true : false
  end
  def validate_ip_port(str)
    str =~ /^#{IP}(:\d+)?$/ ? true : false
  end
  def validate_route(str)
    str.map{|value|
      value =~ /^#{IP}(\/(3[0-2]|[1-2][0-9]|[0-9]))?:#{IP}$/ ? true : false
    }.reduce(:&)
  end
  def validate_peer(str)
    str.map{|value|
      value =~ /^#{IP}(\/(3[0-2]|[1-2][0-9]|[0-9]))?(:\d+)?(,.*)?$/ ? true : false
    }.reduce(:&)
  end
  def validate_int(str)
    str =~ /^\d+$/ ? true : false
  end
  def validate_string(str)
    str =~ /^\S+$/ ? true : false
  end
  def validate_vcc(str)
    str.map{|value|
     value =~ /^#{IP}(:\d+)?\/\d+\/\d+$/ ? true : false 
    }.reduce(:&)
  end
  def validate_all(str)
    true
  end
  def check
    @opts.each{|opt|
      if opt.mandatory and opt.value.nil?
        @str_error << "#{opt.opt} is mandatory"
      elsif opt.mandatory and opt.value.is_a?(Array) and opt.value.size == 0
        @str_error << "#{opt.opt} is mandatory"
      end
      if opt.typo and ( (opt.value.is_a?(Array) and opt.value.size > 0) or (!opt.value.is_a?(Array) and !opt.value.nil?))
        if self.respond_to? "validate_" + opt.typo.to_s
          if ! self.send  "validate_" + opt.typo.to_s,opt.value
            @str_error << "#{opt.opt} with value #{opt.value} need to be a #{opt.typo}"
          end
        else
          @str_error << "Type #{opt.typo} not know for option #{opt.opt}"
        end
      end
    }
    @str_error.map! {|val| "\t" + val }
    if @str_error.size > 0
      raise CmdParse::InvalidArgumentError , "\n" + @str_error.join("\n")
    end
  end
end


def validate(&block)
  t = ValidateCmd::new
  t.instance_eval(&block)
  t.check
end

def format_errors
  begin
    yield
  rescue RuntimeError => e
    warn "ERROR : " + e.message
  else
    if $do_command_error
      warn "Error while lauching command"
    else
      puts "ok"
    end
  end
end

