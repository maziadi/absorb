#!/usr/bin/env ruby

require 'erb'
require 'yaml'

if ARGV.length != 1
    puts "Usage: gen_conservercf.rb <srv-console>"
    exit -1
end

cons_config = YAML::load(File::new("data/consoles/cerealmanager.yaml"))
bauds = baud = Hash.new
if !cons_config["firewall"][ARGV[0]] then
  puts "Erreur : Serveur console introuvable !"
  exit
end
cons_config["firewall"][ARGV[0]].each do |b|
  baud[b[0]] = "baud ".concat(b[1]["baudrate"].to_s) if  b[1].class == Hash and b[1]["baudrate"] != nil
end

host_access = cons_config["access"]["*"]

template = ERB.new(File.read("data/consoles/conserver.cf.erb"))
puts template.result(binding)
