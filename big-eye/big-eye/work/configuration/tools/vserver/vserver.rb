#!/usr/bin/env ruby
require 'erb'
require 'fileutils'
#require 'libvirt'
require 'net/ssh'
require 'open3'
require 'yaml'
require 'pp'


class Vserver

  def initialize(hash = {})
    @hostname = hash[:hostname]
    @cluster  = hash[:cluster]
    @bridges  = hash[:bridges]
    @cpu      = hash[:cpu]
    @mem_size = hash[:memory_size]
    @sys_size = hash[:system_size]
    @img      = hash[:file]
    @windows  = hash[:windows]
    if @sys_size and @mem_size
      @size     = size_in_mega([@sys_size, @mem_size])
    elsif @sys_size
      @size     = size_in_mega([@sys_size])
    end
    # cluster information
    cluster_file = "data/cluster.yaml"
    if @cluster
      @data     = YAML::load(File::open(cluster_file))[@cluster]
      @members  = @data['members'] or false
      @phy_one  = @data['members'][0] or false
      @phy_two  = @data['members'][1] or false
    end
  end

  def used_mac_addr
    used_mac_addr = []
    Dir.glob('dist/nodes/*/etc/libvirt/qemu/*.xml').each do |file|
      f = File.open(file)
      data = f.readlines
      data.each do |l|
        result = l.match(/(([0-f]{2}:){5}[0-f]{2})/i)
        if result
          used_mac_addr << result[1]
        end
      end
    end
    used_mac_addr
  end

  def gen_mac_addr
    addr = "52:54:00:#{'%02x' % (rand * 0xff)}:#{'%02x' % (rand * 0xff)}:#{'%02x' % (rand * 0xff)}"
    addr
  end

  def free_mac_addr
    mac = gen_mac_addr
    used_macs = used_mac_addr
    while used_macs.include?(mac)
      mac = gen_mac_addr
    end
    mac
  end

  def ssh(host, cmd)
    stdout = ""
    Net::SSH::start(host,'root') do |ssh|
      ssh.exec!(cmd) do |channel, stream, data|
        stdout << data.chomp if stream == :stdout
      end
    end
    stdout
  end

  def do_command(cmd, out = false)
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      err = stderr.readlines
      if out
        output = stdout.readlines
        puts output
      end
      warn "error on #{cmd} : \n#{err}" if err.size != 0
    end
  end

  def initialize_cluster
    dir = "dist/nodes/#{@cluster}/etc/libvirt/qemu"
    drbd = "dist/nodes/#{@cluster}/etc/drbd.conf"
    if not File.exist?(dir)
      puts "Create cluster tree on dist/nodes/"
      do_command("mkdir --parents #{dir}")
      do_command("git add #{dir}")
      FileUtils.cp("modules/drbd_1_0/templates/drbd.conf", drbd)
      do_command("git add #{drbd}")
      [@phy_one, @phy_two].each do |host|
        dir = "dist/nodes/#{host}"
        if not File.exist?(dir)
          do_command("mkdir --parents #{dir}")
          do_command("git add #{dir}")
          FileUtils.cd(dir) do
            FileUtils.ln_s("../#{@cluster}/etc", "etc")
          end
          do_command("git add #{dir}/etc")
        end
      end
    end
  end

  def size_in_mega(sizes)
    if sizes.size == 1
      total = 0
    else
      # we add 300Mo for /boot
      total = 300
    end
    sizes.each do |size|
      if size !~ /\d+M|m|\d+g|G/
        raise "You have to specify units for size #{size}"
      elsif size =~ /M|m/
        size.gsub(/\D+/, "")
      elsif size =~ /G|g/
        size = size.gsub(/\D+/, "").to_i * 1024
      end
      total += size.to_i
    end
    free_vg = ssh(@cluster, "vgs --nosuffix --unit m --noheading | awk '{print $7}'").to_i
    raise "No space left on device, #{free_vg}Mo free" if total > free_vg
    total
  end

  # initialize drbd beetwen hosts
  def create_drbd
    one = "#@phy_one:#{@data['ip_drbd'][0]}"
    two = "#@phy_two:#{@data['ip_drbd'][1]}"

    drbd_config_file = "dist/nodes/#{@cluster}/etc/drbd.conf"

    puts "Create physical device on #{@cluster}\n"
    create_drbd = "/opt/local/bin/prepare_device -h #{@hostname} -s #{@size.to_s + "M"} -m #{one} -n #{two}"
    @members.each { |host| ssh(host, create_drbd) }
    puts "update of #{drbd_config_file}\n"
    do_command("tools/refresh.sh #{drbd_config_file}")
    puts "initialise drbd devices"
    initialize_drbd = "drbdadm -- --clear-bitmap new-current-uuid #{@hostname};"
    initialize_drbd += "drbdadm primary #{@hostname}"
    ssh(@cluster, initialize_drbd)
    puts "drbd device initialized"
  end

  def format_volume
    puts "formating volume #{@hostname}"
    ssh(@cluster, "mkfs.xfs /dev/drbd/by-res/#{@hostname}")
  end

  def create_img
    puts "create image file"
    create_img = "/opt/local/bin/prepare_device -h #@hostname -s #@size -i"
    ssh(@cluster, create_img)
    puts "image file created"
  end

  def delete_disk
    puts "delete all data"
    type_drbd = ssh(@cluster, "ls /dev/drbd/by-res/#{@hostname}")
    if type_drbd.empty?
      ssh(@cluster, "rm /data/images/#{@hostname}.img")
    else
      ssh(@cluster, "drbdadm secondary #{@hostname}")
      cmd = "drbdadm disconnect #{@hostname}; drbdadm detach #{@hostname};"
      cmd += "lvremove -f /dev/data/#{@hostname}"
      puts "delete #{@hostname}"
      [@phy_one, @phy_two].each do |host|
        ssh(host, cmd)
      end
      # TODO clean drbd.conf, clean config file
      puts "You must edit dist/nodes/#@cluster/etc/drbd.conf to remove configuration for host #{@hostname}"
      puts "rake publish_prod, and puppetd on cluster members"
    end
  end

  def create_config_file
    used_macs = used_mac_addr
    kvm_config_file = "dist/nodes/#{@cluster}/etc/libvirt/qemu/#{@hostname}.xml"
    puts "Create config file"
    util = "/opt/local/bin/config_vserver create"
    size = size_in_mega([@mem_size])
    generate_config = "#{util} -h #{@hostname} -v #{@cpu} -m #{size} -b network" 
    @bridges.each do |br|
      mac = gen_mac_addr
      # check if mac_addr is alreadry used
      while used_macs.include?(mac)
        mac = gen_mac_addr
      end
      used_macs << mac
      generate_config += " -n #{br},#{mac}"
    end
    generate_config += " -t img" if @img
    generate_config += " --hda" if @windows

    @members.each { |host| ssh(host, generate_config) }
    File.new(kvm_config_file, "w")
    do_command("git add #{kvm_config_file}")
    do_command("tools/refresh.sh #{kvm_config_file}")
    system "rake publish_prod MSG='adding #@hostname config file'"
  end

  def delete_config_file
    puts "delete config file for #{@hostname}"
    xml = "dist/nodes/#{@cluster}/etc/libvirt/qemu/#{@hostname}.xml"
    if File.exist?(xml)
      do_command("rm #{xml}")
    else
      raise "config file for hostname doesn't exist"
    end
    [@phy_one, @phy_two].each do |host|
      ssh(host, "rm -rf /etc/libvirt/qemu/#{@hostname}.xml")
    end
  end

  def update_config
    puts "refresh #@cluster config files"
    Dir.glob("dist/nodes/#{@cluster}/**/*").each do |file|
      if File.file?(file) 
        puts "refresh #{file}"
        do_command("tools/refresh.sh #{file}")
      end
    end
    puts "do : rake publish_prod MSG='update #@cluster config files'"
    puts "ok"
  end

  def puppetize
    [@phy_one, @phy_two].each do |host|
      puts "puppetd on #{host}"
      system "ssh #{host} puppetd --test --verbose"
      puts "done"
    end
  end

  def rebuild_all
    # find the used lv on master
    puts "rebuild all lv on #{@hostname}"
    volumes = ssh(@cluster, "lvs --units k --noheadings")    
    hosts = {}
    stdout = []
    Net::SSH::start(@hostname,'root') do |ssh|
      volumes.split("\n").each do |srv|
        hosts[srv.split(" ")[0]] = srv.split(" ")[3]
      end
      hosts.each do |host, size|
        if host != "swap" and host != "system"
          ssh.exec!("lvcreate -n #{host} -L #{size} data").chomp
          ["-- --force create-md", "attach", "syncer", "connect"].each do |action|
            ssh.exec!("drbdadm #{action} #{host}")
          end
        end
      end
    end
    puts "done"
  end

  def add_vserver
    if @img
      create_img
    else
      create_drbd
    end
    create_config_file
  end

  def delete_vserver
    puts "You have to stop the vserver before erase it"
    puts "and put drbd on secondary for this device"
    puts "virsh destroy $hostname"
    puts "drbdadm secondary $hostname"
    puts "ALL DATA WILL BE ERASE"
    puts "Are you sure that you want to destroy #{@hostname} yes/no"
    answer = STDIN.gets
    if answer !~ /yes|YES|y|Y/
      puts "Nothing to do, exit"
      exit
    end
    delete_config_file
    delete_disk
  end

  def create_volume
    create_drbd
    format_volume
    puts "volume is ready to use, add it to heartbeat"
  end
end
