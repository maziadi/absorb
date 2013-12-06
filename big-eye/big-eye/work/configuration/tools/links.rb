#!/usr/bin/env ruby

FILE_NAME = 'data/atm_links.yaml'

class Hash
    def each()
        ks = keys.sort_by { |k| k.to_s }
        ks.each { |k| yield(k, self[k]) }
    end
    def each_value()
        each { |k, v| yield(v) }
    end
end

require 'yaml'
begin
    require 'cmdparse2'
rescue LoadError => detail
    require 'rubygems'
    require 'cmdparse'
end

def parse_file(file_name)
  hash = YAML::load(File::new(file_name))

  hash.collect { |key, value| 
    Link::new(value) 
  }
end

def search_by_refs(refs) 
  links = parse_file(FILE_NAME)

  refs.collect { |ref|
    links.find { |link| link.ref == ref }
  }.compact
end

def group_by_client(links)
  hash = {}
  links.each { |link|
    (hash[link.destination] ||= []) << link
  }
  hash
end


class Link
  attr_reader :ref
  attr_reader :destination, :label, :client_type, :remark, :ope_type, :liv_ope
  def initialize(hash = {})
    hash.each_pair { |key, value|
      instance_variable_set("@#{key}", value)
    }
  end

  def to_s
    "%15s: %20s / %s" % [ref, destination, label]
  end
end

cmd = CmdParse::CommandParser::new(true, true)
cmd.program_name = "links.rb "
cmd.program_version = [0, 0, 1]

cmd.add_command(CmdParse::HelpCommand::new, true)
cmd.add_command(CmdParse::VersionCommand::new)

search = CmdParse::Command::new('search', false)
search.short_desc = "Search links by references"
search.description = "Search links by references" 

search.options = CmdParse::OptionParserWrapper::new do |opt|
    opt.on('-g', '--group', "Group by destination and labels") { |name|
        $group = true
    }
end

search.set_execution_block do |args|
  $group ||= false

  result = search_by_refs(args)
  if $group
    group_by_client(result).each {|client, links|
      puts "#{client}:"
      puts links.sort_by { |l| l.label || "" }.collect { |l| "  #{l}" }.join("\n")
      puts 
    }
  else
    puts result.join("\n")
  end 
end

cmd.add_command(search)
cmd.parse
