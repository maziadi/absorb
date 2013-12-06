#!/usr/bin/env ruby
#
# Manage libvirt vm configuration
#

require 'yaml'
require 'open4'
require 'socket'

class Libvirt

  def initialize(name, cpu, bridges, memory_size, windows)
    @vmname = name
    @cpu = cpu
    @memory_size = size_in_mega(memory_size)
    @windows = windows
    @bridges = bridges
  end

  def create_config()
    cmd = "/opt/local/bin/config_vserver create -h #{@vmname} -v #{@cpu} -m #{@memory_size} -b network"
    @bridges.each { |bridge|
      mac = gen_mac_address
      cmd += " -n #{bridge},#{mac}"
    }
    cmd += " --hda" if @windows
    do_command cmd
  end

  def gen_mac_address
    addr = "52:54:00:#{'%02x' % (rand * 0xff)}:#{'%02x' % (rand * 0xff)}:#{'%02x' % (rand * 0xff)}"
    addr
  end

  def self.delete(name)
    do_command "rm -f /etc/libvirt/qemu/#{name}.xml"
    begin
      do_command "crm resource show | grep #{name}"
    rescue
      return 0
    end
    do_command "crm configure delete mail_#{name}"
    do_command "crm configure delete drbd_#{name}"
    do_command "crm configure delete kvm_#{name}"
  end

  def self.prov_cluster(name,preferred)
    do_command("/opt/local/bin/pm_vmprov.rb -h #{name} -p #{preferred}")
  end
end
