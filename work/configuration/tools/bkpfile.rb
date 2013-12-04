#!/usr/bin/env ruby

puts "maybe obsoleted"
exit

begin
    require 'cmdparse2'
rescue LoadError => detail
    require 'rubygems'
    require 'cmdparse'
end
require 'open3'

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model.rb'
  require 'tools/libalpha.rb'
else
  require_relative 'model'
  require_relative 'libalpha'
end

require 'erb'
require "fileutils"

include Open3

def exec_cmd(cmd)
  if ! $simulate then
    system(cmd)
  end
end

def search_options(opt)
    opt.on('-s', '--simulate', "Do nothing, just print what we have to do") { |simulate|
      $simulate = simulate
    }
    opt.on('-h', '--hostname HOSTNAME', "Hostname, regexp") { |hostname|
      $hostname = hostname
    }
    opt.on('-e', '--expression EXPRESSION', "Expression to evaluate") { |expression|
      $expression = expression
    }
    opt.on('-a', '--ancestor ANCESTOR_NAME', "Name of the ancestor to search children for") { |ancestor|
      $ancestor = ancestor
    }
    opt.on('-f', '--filename FILENAME', "Filename to save (default to /etc/network/interfaces)") { |filename|
      $filename = filename
    }
end

def do_search()
    Model::load().find_hosts($hostname,
        :ancestor => $ancestor, :where => $expression)
end

cmd = CmdParse::CommandParser::new(true, true)
cmd.program_name = "bkpfile.rb "
cmd.program_version = [0, 0, 1]

cmd.add_command(CmdParse::HelpCommand::new, true)
cmd.add_command(CmdParse::VersionCommand::new)

save = CmdParse::Command::new('save', false)
save.short_desc = "Save a distant file for a host"
save.description = "Save a distant file for a host"
save.description << """
    Hostname define :
    - by name (regexp),
    - by attribute (expression):
        - 'key == false'
        - 'admin_addr =~ /^217.15.*/'
        - '!check.nil?'
    - by ancestor
"""
save.options = CmdParse::OptionParserWrapper::new do |opt|
    search_options(opt)
end

save.set_execution_block do |args|
    $expression ||= nil
    $ancestor ||= nil
    $hostname ||= nil
    $compact ||= false
    $filename ||= "/etc/network/interfaces"

    if $hostname.nil? and $expression.nil? and $ancestor.nil? then
      raise CmdParse::InvalidArgumentError,"You have to specify something to choose hosts"
    end

    if $filename.match('^/.*').nil? then
      puts "Nom de fichier invalide !"
      exit
    end

    do_search().collect { |host|
      $erreur = 0
      file = Tempfile.new(File.basename($filename))
      puts ""
      puts "-" * 10
      puts "Connecting to host #{host.name} ..."
      if ! $simulate then
        stdin, stdout, stderr = popen3("scp #{host.name}:#{$filename} #{file.path}")
        stderr.each { |line|
          puts line
          $erreur = $erreur + 1
        }
      end
      if $erreur == 0 then
        if ! File.directory?("dist/nodes/#{host.name}#{File.dirname($filename)}") then
          exec_cmd("svn mkdir --parents dist/nodes/#{host.name}#{File.dirname($filename)}")
        end
        exec_cmd("cp #{file.path} dist/nodes/#{host.name}#{$filename} && chmod 755 dist/nodes/#{host.name}#{$filename}")
        exec_cmd("svn st dist/nodes/#{host.name}#{$filename} | grep -q ^? && svn add --parents dist/nodes/#{host.name}#{$filename}")
        puts "Added dist/nodes/#{host.name}#{$filename}"
      else
        puts "Erreur #{host.name} #{$filename}"
      end
      if ! $simulate then
        stdin.close
        stdout.close
        stderr.close
        file.unlink
      end
    }
end

cmd.add_command(save)
cmd.parse
