#!/usr/bin/env ruby
#
# Manage DRBD
#

require 'yaml'
require 'open4'
require 'socket'

class Drbd

  def initialize(name, size, hosts)
    @name = name
    @size = size
    @host1 = hosts.to_a.first
    @host2 = hosts.to_a.last
  end

  def create()
    do_command "/opt/local/bin/prepare_device -h #{@name} -s #{@size.to_s + "M"} -m #{@host1} -n #{@host2}"
    do_command "sleep 1"
  end

  def self.init(name)
    do_command "sleep 3; drbdadm -- --clear-bitmap new-current-uuid #{name}"
  end

  def self.reset(name)
    do_command "drbdadm detach #{name}; drbdadm disconnect #{name}; sleep 1"
  end

  def self.delete(name, keeplv)
    do_command "drbdadm detach #{name}"
    do_command "drbdadm disconnect #{name}"
    do_command "sleep 1"
    do_command "rm /etc/drbd.d/#{name}.res"
    do_command "lvremove -f /dev/data/#{name}" if !keeplv
    do_command "sleep 1"
  end

  def self.list(short)
    do_command "drbd-overview"
  end
end
