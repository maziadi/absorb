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
  "2.3CS",
  "2C250",
  "2C320",
  "2C500",
  "2C75S",
  "2C150S",
  "2GS",
  "4C1000S",
  "4C2000S",
  "4C2S",
  "4C500S",
  "4GS",
  "8C1000S",
  "CN2",
  "FO10M",
  "FO15M",
  "FO20M",
  nil # QOS vide
]
#
# script
#
require 'rubygems'
require 'tmail'
require 'yaml'
require 'augeas'


def check_qos(qos)
  raise RuntimeError, "Incorrect qos: '#{qos}'" unless QOS.index qos
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
      puts "           !!!!!!! - analyze: l = #{label}, qos = #{qos}, ref = #{ref}, date = #{date}, remark = #{remark}"
      puts "           !!!!!!! - error detail: " + e.to_s
      nil
    end
end

def analyse_config_atm
  hash = {}
  itfs = {}

  aug = Augeas::open("./tmp","./tools/augeas",0) #lenses for augeas need to be in tools/augeas

  #first we look if there is failed parse
  aug.match("/augeas/files/*[error='parse_failed']").each{ |file|
    if file =~ /\.atmudp/
      line = aug.get("#{file}/error/line")
      char = aug.get("#{file}/error/char")
      puts  "!!!! ERROR PARSING #{File::basename(file)} at line #{line} char #{char}"
    end
  }
  files = aug.match("/files/*")
  files.each do |file|
    if file =~ /\.atmudp/ #if its a atmudp file

      #default value
      destination = nil
      comment = nil
      prec = nil
      prec_prec = nil

      portal = File::basename(file).gsub(/.atmudp$/, "")
      puts "Portal : #{portal}"
      search = aug.match("#{file}/*[label()='#comment' or label()='ROUTE']").each do |val| #search all comment and ROUTE
        if val =~ /#comment/   #we check comment and analyse 
          com = aug.get("#{val}")
          comment = analyse_comment(com) if com[0..0] != "#" and com[0..5] != "ROUTE=" #we parse just simple comment
        end
        if prec_prec =~ /#comment/ and prec =~ /#comment/ and val =~ /#comment/ #maybe new destination
          comment1 = aug.get(prec_prec)
          comment3 = aug.get(val)
          if comment1 =~ /######/ and comment3 =~ /######/ #sure its a new dest
            header = aug.get(prec)
            newdest = header.gsub(/^([^#]+) #[ ]*$/, '\1')
            if header != newdest
              destination = newdest.upcase.strip
              puts "Nouvelle destination: '#{destination}'"
            end
          end
        end
        if val =~ /ROUTE/
          itf1 = aug.get("#{val}/vcc[1]/itf")
          vp1 = aug.get("#{val}/vcc[1]/vp")
          vc1 = aug.get("#{val}/vcc[1]/vc")
          itf2 = aug.get("#{val}/vcc[2]/itf")
          vp2 = aug.get("#{val}/vcc[2]/vp")
          vc2 = aug.get("#{val}/vcc[2]/vc")
          puts "  Route: '#{itf1} #{vp1} / #{vc1} / #{itf2} #{vp2} / #{vc2}' / #{comment.inspect}"
          if comment
            peer = aug.match("#{file}/*[label()='ITF'][id='#{itf2}']")
            peer_ip = aug.get("#{peer}/ip")
            peer_port = aug.get("#{peer}/port")
            link = {
                :label => comment[:label],
                :remark => comment[:remark],
                :ref => comment[:ref],
                :ope_type => comment[:qos][0],
                :liv_ope => "#{vp1}/#{vc1}",
                :date => comment[:date],
                :portal => portal,
                :peer => "#{peer_ip}:#{peer_port}",
                :destination => destination
            }
            if comment[:qos].length == 2
               link[:client_type] = comment[:qos][1] 
            end
            hash[comment[:ref]] = link
            comment = nil
          end
        end
        prec_prec = prec
        prec = val
      end
    end
  end
  hash
end

links = {}
links = analyse_config_atm
File::open('data/atm_links2.yaml', 'w') { |file| file.write links.to_yaml }
