#!/usr/bin/env ruby
require 'erb'
require 'fileutils'
#require 'libvirt'
require 'net/ssh'
require 'open4'
require 'yaml'
require 'pp'

def do_command(cmd)
  pid, stdin, stdout, stderr = Open4::popen4(cmd)
  ignored, status = Process::waitpid2 pid
  stdout.readlines.each { |line| puts line }
  stderr.readlines.each { |line| puts line }
  raise "Impossible to execute command #{cmd} : stderr" if status.exitstatus != 0
  status.exitstatus
end


class Vserver2

  def initialize(hash = {})
    @hostname = hash[:hostname]
    @cluster  = hash[:cluster]
    @bridges  = hash[:bridges]
    @cpu      = hash[:cpu]
    @mem_size = hash[:memory_size]
    @sys_size = hash[:system_size]
    @prefered  = hash[:prefered]
    @hda  = hash[:hda]
    # cluster information
    cluster_file = "data/cluster.yaml"
    if @cluster
      @data     = YAML::load(File::open(cluster_file))[@cluster]
      raise "Impossible de trouver le cluster !" if @data == nil
      raise "Cette version de vserverprov ne prend en charge que les cluster kvm v2" if @data['version'] != "2" 
      @members  = @data['members'] or false
      @phy_one  = @data['members'][0] or false
      @phy_two  = @data['members'][1] or false
    end
    # verfier que les deux hosts du cluster sont up et que prefered est un des deux hosts
    begin
      do_command("ssh #{@members.first} /bin/true")
      do_command("ssh #{@members.last} /bin/true")
    rescue
      puts "Impossible de contacter les deux membres du cluster ! Assurez-vous qu'ils soient opérationnels tous les deux avant de poursuivre."
      exit 1
    end
    # Initialisation du cluster
    if ! File.exist?("dist/nodes/#{@cluster}/etc/libvirt/qemu") then
      do_command("mkdir --parents dist/nodes/#{@cluster}/etc/libvirt/qemu")
      do_command("git add dist/nodes/#{@cluster}/etc/libvirt/qemu")
      do_command("mkdir --parents dist/nodes/#{@members.first}")
      do_command("git add dist/nodes/#{@members.first}")
      do_command("mkdir --parents dist/nodes/#{@members.last}")
      do_command("git add dist/nodes/#{@members.last}")
      @members.each { |host|
        FileUtils.cd("dist/nodes/#{host}") do
          FileUtils.ln_s("../#{@cluster}/etc", "etc")
          do_command("git add etc")
        end
      }
    end
  end

  def ssh(host, cmd)
    puts host + " : " + cmd
    stdout = ""
    #Net::SSH::start(host,'root') do |ssh|
    #  ssh.exec!(cmd) do |channel, stream, data|
    #    stdout << data.chomp if stream == :stdout
    #  end
    #end
    stdout = do_command("ssh root@#{host} #{cmd}")
    puts stdout
    stdout
  end

  # initialize drbd beetwen hosts
  def create_drbd
    one = "#@phy_one:#{@data['ip_drbd'][0]}"
    two = "#@phy_two:#{@data['ip_drbd'][1]}"

    puts "Create physicals devices on #{@cluster} members\n"
    @members.each { |host|
      ssh(host, "vmprov -h #{@hostname} drbd add -s #{@sys_size} -m #{one} -n #{two}")
    }
    ssh(@members.first, "vmprov -h #{@hostname} drbd init")
    puts "initialise drbd devices"
    @members.each { |host|
      ssh(host, "vmprov -h #{@hostname} drbd reset")
    }
    sleep 5
    puts "drbd device initialized"
  end

  def delete_disk
    puts "Delete all data"
    @members.each { |host|
      ssh(host, "vmprov -h #{@hostname} drbd delete")
    }
  end

  def create_config_file
    puts "Create config file"
    bridges = ""
    @bridges.each { |bridge|
      bridges += "-b #{bridge} "
    }
    cmd = "vmprov -h #{@hostname} vm add #{bridges} -c #{@cpu} -m #{@mem_size}"
    cmd += " --hda" if @hda
    ssh(@members.first, "#{cmd} > /tmp/logconf 2>&1")
    # create dist/nodes file
    File.new("dist/nodes/#{@cluster}/etc/libvirt/qemu/#{@hostname}.xml","w")
    do_command("tools/refresh.sh dist/nodes/#{@members.first}/etc/libvirt/qemu/#{@hostname}.xml")
    do_command("git add dist/nodes/#{@cluster}/etc/libvirt/qemu/#{@hostname}.xml")
    do_command("scp dist/nodes/#{@cluster}/etc/libvirt/qemu/#{@hostname}.xml #{@members.last}:/etc/libvirt/qemu/#{@hostname}.xml")
  end

  def delete_config_file
    puts "Delete config file"
    @members.each { |host|
      ssh(host, "vmprov -h #{@hostname} vm delete")
    }
    do_command("rm dist/nodes/#{@cluster}/etc/libvirt/qemu/#{@hostname}.xml")
  end

  def prov_pacemaker
    puts "Provisionning cluster ..."
    ssh(@members.first, "vmprov -h #{@hostname} vm prov -p #{@prefered}")
    sleep 3
    puts "All done, please verify all is OK on cluster !!"
  end

  def add_vserver
    raise "#{@prefered} ne fait pas parti du cluster #{@cluster} !" if ! @members.include?(@prefered)
    create_drbd
    create_config_file
    prov_pacemaker
  end

  def delete_vserver
    puts "La VM doit être arrêtée avant de continuer !!"
    puts "Assurez-vous que le drbd soit bien en unconfigured !"
    puts "Voir le wiki Pacemaker pour stopper une machine avec son drbd"
    puts "Etes vous sur de vouloir continuer #{@hostname} ? oui/non"
    answer = STDIN.gets
    if answer =~ /^(?:oui|o)$/i
      delete_config_file
      delete_disk
    else
      puts "J'abandonne, vous êtes trop fort !"
      exit
    end
  end
end
