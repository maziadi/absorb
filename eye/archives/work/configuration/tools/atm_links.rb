#!/usr/bin/env ruby


# Pour maintenir les Hash triées par clé
class Hash
    def each()
        ks = keys.sort_by { |k| k.to_s }
        ks.each { |k| yield(k, self[k]) }
    end
    def each_value()
        each { |k, v| yield(v) }
    end
end

#
# Donnees
#

# Mapping des noms de clients vers les noms de clients SI
mapping = {
}

QOS = [
  "0.4C",
  "0.5CS",
  "0.5GS",
  "0.9C150",
  "0.9C320",
  "0.9C75",
  "0.9G",
  "1C150",
  "1C75S",
  "1GS",
  "2CS",
  "2.3CS",
  "2C250",
  "2C320",
  "2C500",
  "2C75S",
  "2C150S",
  "2GS",
  "4C1000S",
  "4C2000S",
  "4.6C500S",
  "4C2S",
  "4C500S",
  "4GS",
  "8C1000S",
  "CN2",
  "FO6M",
  "FO10M",
  "FO15M",
  "FO20M",
  "FO30M",
  "FO40M",
  "FO100M",
  "8C2000S",
  nil # QOS vide
]
#
# script
#
require 'rubygems'
require 'tmail'
require 'yaml'


def check_qos(qos)
    raise RuntimeError, "Incorrect qos: '#{qos}'" unless QOS.index qos
end

def analyse_route(route)
    src, dst, qos = route.split(/:/)
    raise RuntimeError, "Incorrect route format for: '#{route}'" unless qos || dst
    src, qos1 = src.split('-')
    check_qos(qos || qos1)
    src = src.split('.')
    raise RuntimeError, "Incorrect route source format for: '#{route}'" unless src.length == 3 
    dst = dst.split('.')
    raise RuntimeError, "Incorrect route destination format for: '#{route}'" unless dst.length == 3 
    [src, dst, qos]
end

def analyse_comment(comment)
    pattern = /^(.+) ([A-Za-z0-9\/.+]+) \(([A-Z0-9]+)\) ?([0-9]+\/[0-9]+\/[0-9]+)? ?(.*)$/ 
    begin
        if (pattern =~ comment)
            label, qos, ref, date, remark = $1, $2, $3, $4, $5
            if date
                elts = date.split('/').collect { |v| v.to_i }
                if elts[2] >= 31
                    elts = elts.reverse
                end
                date = Date::new(*elts)
            end
            if /\// =~ qos
                qos = qos.split(/\//)
            else 
                qos = [qos]
            end
            check_qos(qos[0])
            
            #[label, qos, ref, date, remark]
            "l = #{label}, qos = #{qos}, ref = #{ref}, date = #{date}, remark = #{remark}"
            { :label => label, :qos => qos, :ref => ref, :date => date, :remark => remark }
        else
            puts "           !!!!!!! Unrecognized comment : '#{comment}'"
            nil
        end
    rescue Object => e 
        puts "           !!!!!!! Unable to parse: #{comment}" 
        puts "           !!!!!!! - analyze: l = #{label}, qos = #{qos.join("/")}, ref = #{ref}, date = #{date}, remark = #{remark}"
        puts "           !!!!!!! - error detail: " + e.to_s
        nil
    end
end

def analyse_config_atm(file)
    puts "Analyse du fichier '#{file.path}'"
    portal = File::basename(file.path).gsub(/.atmudp$/, "")
    lines = file.readlines.collect { |line| line.chomp.strip }
    destination = nil
    comment = nil
    hash = {}
    itfs = {}
    while (line = lines.shift)
        case line
        when ''
            # ignore
        when /^DAEMON/
            # ignore
        when /^ITF.*=.*socket:/ # ITF=socket:77:83.167.140.158:2600:1
            elts = line.split(/:/)
          if elts.size >= 4
              itfs[elts[1]] = elts[2] + ":" + elts[3]
            else
              puts "           !!!!!!! ITF invalide: '#{line}" 
            end
        when /^ITF/ 
            # ignore 
        when /^QOS/
            # ignore
        when /^######/
            # beginning of a header ?
            header = lines.shift
            nextline = lines.shift
            if /^#######/ =~ nextline
                # seems so
                newdest = header.gsub(/^[ ]*# ([^#]+) #[ ]*$/, '\1')
                if header != newdest
                    destination = newdest.upcase.strip
                    puts "Nouvelle destination: '#{destination}'"
                end
            end
        when /^ROUTE=(.*)$/
            route = analyse_route($1)
            puts "  Route: '#{route.join(' / ')}' / #{comment.inspect}"
            if comment
                link = {
                    :label => comment[:label],
                    :remark => comment[:remark],
                    :ref => comment[:ref],
                    :ope_type => comment[:qos][0],
                    :liv_ope => route[0].slice(1..2).join('/'),
                    :date => comment[:date],
                    :portal => portal,
                    :peer => itfs[route[1][0]],
                    :destination => destination
                }
                if comment[:qos].length == 2
                   link[:client_type] = comment[:qos][1] 
                end
                if (hash.has_key?(comment[:ref])) 
                  puts "           !!!!!!! Reference deja presente"
                else
                  hash[comment[:ref]] = link
                end
            else
              puts "           !!!!!!! Pas de commentaire pour cette route"
            end
            comment = nil
        when /^# (.*)/
            comment = analyse_comment($1) if destination
        when /^##/
            # ignore
        when /^#(ROUTE|QOS)/
            # ignore
        else
            puts "           !!!!!!! Unrecognized line: '#{line}'"
        end
    end 
    hash
end

links = {}
Dir['/tmp/*.atmudp'].each { |filename|
    File::open(filename) { |file| links.merge! analyse_config_atm(file) }
}

File::open('data/atm_links.yaml', 'w') { |file| file.write links.to_yaml }
File::open('dist/nodes/si-erp-tech-1/etc/anderson/atm_links.yaml', 'w') { |file| file.write links.to_yaml }
