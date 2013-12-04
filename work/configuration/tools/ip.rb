#!/usr/bin/env ruby

require 'ftools'

begin
    require 'cmdparse2'
rescue LoadError => detail
    require 'rubygems'
    require 'cmdparse'
end
require 'rubygems'
require 'netaddr'

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
else
  require_relative 'model'
end

def create_range(str, tags = {})
    min, max = str.split(/ - /)
    raise ArgumentError, "Unparsable IP range: '#{str}'" if max.nil?
    ip_net_range = NetAddr.range(min, max, :Inclusive => true, :Objectify => true)
    merged = NetAddr.merge(ip_net_range, :Objectify => true)
    raise ArgumentError, "'#{str}' could not be reduced to a single CIDR range" if merged.length > 1 
    merged.first.tag.merge! tags
    merged.first
end

def format_inetnum(inetnum, compact = false, attribute = nil)
    if compact
        if attribute.nil?
            inetnum.range + ": " + inetnum.instance_variables.collect { |name|
                val = inetnum.instance_variable_get(name)
                val = val.desc if name == "@subnet"
                "#{name[1..-1]} = #{val.kind_of?(Array) ? val.join('; ') : val}"
            }.join(", ")
        else
            val = inetnum.instance_variable_get("@#{attribute}")
            val = val.desc if attribute == "subnet"
            "#{inetnum.range}: #{val.kind_of?(Array) ? val.join('; ') : val}" 
        end
    else
        inetnum.to_s
    end
end

def search_options(opt)
    opt.on('-e', '--expression EXPRESSION', "Expression to evaluate") { |expression|
        $expression = expression
    }
    opt.on('-c', '--compact [ATTR]', "Compact output (one inetnum per line)") { |name|
        $compact = true 
        $attribute = name == "" ? nil : name
    }
    opt.on('-t', '--tree', "Tree view output") { |name|
        $tree = true 
    }
end

def do_search(pattern, params = {})
    pattern = pattern.split(/,/)
    puts "Searching for #{pattern.join(', ')}"
    model = IpModel::load().find_inetnums(pattern, params).sort_by { |i| i.range }
end

cmd = CmdParse::CommandParser::new(true, true)
cmd.program_name = "ip.rb "
cmd.program_version = [0, 0, 1]

cmd.add_command(CmdParse::HelpCommand::new, true)
cmd.add_command(CmdParse::VersionCommand::new)

search = CmdParse::Command::new('search', false)
search.short_desc = "Search for an INETNUM"
search.description = "Search for a INETNUM"
search.description << """
    - by range (regexp),
    - by attribute (expression):
"""
search.options = CmdParse::OptionParserWrapper::new do |opt|
    search_options(opt)
    opt.on('-x', '--count', "Count addresses") { |name|
        $count = true 
    }
end

def dump_tree(tree, nets, depth = 0)
    nets.collect { |net|
        ("  " * depth) + "#{net.desc}: #{net.tag['netname']}\n" +  
        dump_tree(tree, tree.children(net), depth + 1)
    }.join("")
    
end

search.set_execution_block do |args|
    $expression ||= nil
    $compact ||= false
    $inetnum_pat = args.size > 0 ? args.first : ''
    prefix = ""
    count = 0
    results = do_search($inetnum_pat, :where => $expression) 
    if $tree
        tree = NetAddr::Tree.new()
        results.each { |inetnum|
            tree.add! create_range(inetnum.range, 'netname' => inetnum.netname) 
        }
        puts tree.show
        puts "Test: "
        puts dump_tree(tree, tree.supernets) 
    else
        puts results.collect { |inetnum|
            if $count
                prefix = "%4d " % inetnum.size
                count += inetnum.size
            end
            prefix + format_inetnum(inetnum, $compact, $attribute)
        }.join("\n" + ($compact ? "" : "\n")) 
        if $count
            puts "Total number of addresses: #{count}"
        end 
    end
end

cmd.add_command(search)
cmd.parse
