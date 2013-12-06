#!/usr/bin/env ruby

require "optparse"
require "log4r"
require "open3"
require "open4"
require 'log4r/outputter/syslogoutputter'

include Log4r

@logger = Logger.new 'pm_vmprov'
@logger.level = INFO
lo = Outputter.stdout
lo.level = INFO
@logger.outputters << lo
lo = SyslogOutputter.new("pm_vmprov")
lo.level = INFO
@logger.outputters << lo

options = {}
@simulate = false

def do_command(cmd, out = true, simulate = false)
  @logger.debug "#{cmd}"
  if @simulate then
    @logger.info "Simulate, no action for #{cmd}"
  else
    pid, stdin, stdout, stderr = Open4::popen4(cmd)
    ignored, status = Process::waitpid2 pid
    err = stderr.readlines
    out = stdout.readlines
    if status.exitstatus != 0 or err.size != 0 then
      @logger.error "error on #{cmd}"
      err.each { |line| @logger.error line }
      out.each { |line| @logger.error line }
      exit -1
    end
  end
end

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on("-s", "--simulate", "Do nothing, just print what we have to do") do |s|
    @simulate = true
  end
  opts.on("-h","--hostname H", String, "Hostname of the virtual machine we have to provision") do |h|
    options[:hostname] = h
  end
  opts.on("-p","--prefered H", String, "Hostname of the prefered host for the virtual machine") do |p|
    options[:prefered] = p
  end
  opts.on_tail("--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

@logger.info "Provisionning VM #{options[:hostname]} ..."

# drbd-overview doit rendre unconfigured
do_command "drbd-overview | grep #{options[:hostname]} | grep Unconfigured"
# virsh define doit redonner la vm
do_command "virsh define /etc/libvirt/qemu/#{options[:hostname]}.xml"

# verify vm does not exist in pacemaker conf
pid, stdin, stdout, stderr = Open4::popen4("crm resource show | grep \"#{options[:hostname]} \"")
ignored, status = Process::waitpid2 pid
if status.exitstatus == 0 then
  @logger.error "Verification failed : VM #{options[:hostname]} already exist in Pacemaker configuration"
  stderr.readlines.each { |line| @logger.error line }
  stdout.readlines.each { |line| @logger.error line }
  exit -1
end
@logger.debug "Verification OK : VM #{options[:hostname]} doesn't exist in Pacemaker configuration"

# drbd ressource
@logger.debug "Configure drbd ressource #{options[:hostname]}"
do_command "crm configure primitive drbd_#{options[:hostname]} ocf:linbit:drbd params drbd_resource='#{options[:hostname]}' op monitor role='Master' interval='10s' op monitor role='Slave' interval='20s' op start timeout='240s' op stop timeout='100s'"
do_command "sleep 3"
do_command "crm configure ms ms_drbd_#{options[:hostname]} drbd_#{options[:hostname]} meta master-max='2' notify='true' interleave='true' target-role='Master'"

# kvm ressource
@logger.debug "Configure kvm ressource #{options[:hostname]}"
do_command "crm configure primitive kvm_#{options[:hostname]} ocf:heartbeat:VirtualDomain params config='/etc/libvirt/qemu/#{options[:hostname]}.xml' migration_transport='tcp' meta allow-migrate='true' target-role='Started' is-managed='true' op start timeout='90s' op stop timeout='90s' op monitor interval='10s' timeout='30s' op migrate_to timeout='180s'"

# prefered host location
@logger.debug "Configure prefered host location for #{options[:hostname]}"
do_command "crm configure location loc_#{options[:hostname]} kvm_#{options[:hostname]} 200: #{options[:prefered]}"

# mail alert
@logger.debug "Configure mail alert for vm #{options[:hostname]}"
do_command "crm configure primitive mail_#{options[:hostname]} ocf:heartbeat:MailTo params email='root' subject='#{options[:hostname]}'"

# colocation
@logger.debug "Configure colocation for ressources"
do_command "crm configure colocation #{options[:hostname]}_alert inf: mail_#{options[:hostname]} kvm_#{options[:hostname]}"
do_command "crm configure colocation #{options[:hostname]}_on_masterDRBD inf: kvm_#{options[:hostname]} ms_drbd_#{options[:hostname]}:Master"

# order constraint
@logger.debug "Configure order constraint for kvm on drbd"
do_command "crm configure order #{options[:hostname]}_on_drbd inf: ms_drbd_#{options[:hostname]}:promote kvm_#{options[:hostname]}:start"

@logger.info "provisionning VM #{options[:hostname]} done"
