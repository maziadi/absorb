#!/usr/bin/env ruby
# lib pour gérer les options cmdparse
# http://cmdparse.rubyforge.org/tutorial.html
require 'erb'
require 'yaml'
require 'fileutils'


include FileUtils

class Vserver
  def initialize(vserver, file)
    @verser = vserver
    @file   = file
    @master = "xen-2-cbv1"
    @nodes= [ "xen-1-cbv1", "xen-1-ext1", "xen-2-cbv1", "xen-2-ext1", "xen-3-cbv1", "xen-3-ext1" ]
  end
  def send_command(command)
    @command = command
    system "ssh #{@master} #{command}"
  end
  def copy_config_file(path)
    @path = path
    system "scp #{@file} #{@master}:#{path}"
  end
  def deploy_config
    @nodes.each do |node|
      copy_config_file("/etc/xen/")
    end
  end
  def ha_resources_prov
    copy_config_file("#{@master}", "/tmp/")
    send_command("cibadmin -C -o resources -x /tmp/#{@file}")
  end
  def ha_constraints_prov
    copy_config_file("#{@master}", "/tmp/")
    send_command("cibadmin -C -o constraints -x /tmp/#{@file}")
  end
  def cluster_prov
    if @file.to_s =~ /cfg$/
      deploy_config
    end
    if @file.to_s =~ /^resources/
      ha_resources_prov
    end
    if @file.to_s =~ /^constraints/
      ha_constraints_prov
    end
  end
end

domu = ARGV[0]

system "ruby tools/vserver/create_domu_yaml.rb"

Domu = Struct::new(:hostname, :memory, :vcpu, :bridge, :size, :target)

servers = YAML::load(File::open('tools/vserver/domu.yaml'))


servers.collect do |server|
  if server.hostname == domu 
    # les fichiers erp et les variables necessaires pour generer les fichiers de configurations
    #files = [ 'constraints-name.xml', 'hostname.cfg', 'resources-name.xml' ]
    files = [ 'hostname.cfg' ]
    hostname, memory, vcpu, bridge, size, target = server.hostname, server.memory, server.vcpu, server.bridge, server.size, server.target 
    files.each do |file|
      # ouverture du fichier template
      template = ERB.new(File.read('tools/vserver/data/' + file))
      
      # creation du fichier de configuration
      file["hostname"] = "#{hostname}"
      
      f = File.new(file, 'w')
      f.puts template.result(binding)
      f.close

      # inclusion des fichiers dans le cluster
      conf = Vserver.new("#{domu}", "#{file}")
      conf.cluster_prov
      File.delete("#{file}")
    end
  end
end
File.delete('tools/vserver/domu.yaml')
