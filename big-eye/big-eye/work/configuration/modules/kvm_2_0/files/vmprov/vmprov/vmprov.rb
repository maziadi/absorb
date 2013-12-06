#!/usr/bin/env ruby
#
# Provisionning Virtual Machine
#

require 'yaml'
require 'open4'
require 'socket'

def do_command(cmd)
#  puts cmd
#  return 0
  pid, stdin, stdout, stderr = Open4::popen4(cmd)
  ignored, status = Process::waitpid2 pid
  stdout.readlines.each { |line| puts line }
  stderr.readlines.each { |line| puts line }
  raise "Impossible to execute command #{cmd} : stderr" if status.exitstatus != 0
  return status.exitstatus
end

def size_in_mega(size)
  if size !~ /\d+M|m|\d+g|G/
    raise "You have to specify units for size #{size}"
  elsif size =~ /M|m/
    size = size.gsub(/\D+/, "").to_i
  elsif size =~ /G|g/
    size = size.gsub(/\D+/, "").to_i * 1024
  end
  p size
  size
end

class Vserver2

  def initialize(options = {})
    @vmname = options[:hostname]
    @cpu = options[:cpu]
    @memsize = size_in_mega(options[:memory_size])
    @windows = options[:windows]
    @bridges = []
    options[:bridges].each { |bridge|
      self.addbridge(bridge)
    }
    @hosts = {"kvm-dev-3-por1" => "192.168.82.1", "kvm-dev-4-por1" => "192.168.82.2"}
    @disk_size = size_in_mega(options[:system_size])
    @disk = Drbd::new(@vmname, @disk_size, @hosts)
    @conf_libvirt = Libvirt::new(@vmname, @cpu, @bridges, @memsize, @windows)
  end

  def addbridge(brname)
    @bridges << brname
  end

  def create()
    puts "Creation of virtual machine #{@vmname}"
    @disk.create
    @conf_libvirt.create_config
    hostname = Socket.gethostname
    do_command "/opt/local/bin/pm_vmprov.rb -h #{@vmname} -p kvm-dev-4-por1" if hostname == "kvm-dev-4-por1"
  end

  def read()
  end

  def delete()
    puts "Delete virtual machine #{@vmname}"
    @disk.delete
  end

  def update()
  end

end
