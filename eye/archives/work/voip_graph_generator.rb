#!/usr/bin/env ruby

begin
    require 'cmdparse2'
rescue LoadError => detail
    require 'rubygems'
    require 'cmdparse'
end

require 'json'
require 'open-uri'

$vno = 'D200911200001'
$account = '*'
$server = 'thomas-3-por1'
$host = 'scscf-2-maquette'
$indicators = ["NER", "ASR", "CC", "CPS", "ACD", "SMH"]
$from = '-1d'
$until = 'now'
$width = '500'
$height = '300'
$description = """
  Indicators :
    - NER : Network Effectiveness Ratio (success + 4xx / success + 4xx + other_failures)
    - ASR : Answer Seizure Ratio (success / success + 4xx + other_failures)
    - CC : Connected Calls
    - CPS : Calls Per Second
    - ACD : Average Call Duration (sum of call durations / success)
    - SMH : Switched Minutes per Hour (hitCount per hour applied to the sum of call durations)
  
  From & Until Usage :
      --from -8d --until -7d
      (shows same day last week)
      
      --from 04:00_20110501 --until 16:00_20110501
      (shows 4AM-4PM on May 1st, 2011)
      
      --from 20091201 --until 20091231
      (shows December 2009)
      
      --from noon+yesterday
      (shows data since 12:00pm on the previous day)
      
      --from 6pm+today
      (shows data since 6:00pm on the same day)
      
      --from january+1
      (shows data since the beginning of the current year)
      
      --from monday
      (show data since the previous monday)
"""

def generate_ner(host, vno, account)
  {
    "title" => "NER-#{account == "*" ? vno : account}",
    "yMin" => "0",
    "target" => [
      "cactiStyle(alias(asPercent(sum(#{host}.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.Inbound{CallSuccess,CallsEndingWith4xx}-#{account}),sum(#{host}.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.Inbound{CallSuccess,CallsEndingWith4xx,OtherCallFailures}-#{account})),\"IN\"))",
      "cactiStyle(alias(asPercent(sum(#{host}.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.Outbound{CallSuccess,CallsEndingWith4xx}-#{account}),sum(#{host}.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.Outbound{CallSuccess,CallsEndingWith4xx,OtherCallFailures}-#{account})),\"OUT\"))"
    ],
    "yMax" => "100",
    "from" => $from,
    "until" => $until,
    "width" => $width,
    "height" => $height
  }
end

def generate_asr(host, vno, account)
  {
    "title" => "ASR-#{account == "*" ? vno : account}",
    "yMin" => "0",
    "target" => [
      "cactiStyle(alias(asPercent(sum(#{host}.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.InboundCallSuccess-#{account}),sum(#{host}.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.Inbound{CallSuccess,CallsEndingWith4xx,OtherCallFailures}-#{account})),\"IN\"))",
      "cactiStyle(alias(asPercent(sum(#{host}.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.OutboundCallSuccess-#{account}),sum(#{host}.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.Outbound{CallSuccess,CallsEndingWith4xx,OtherCallFailures}-#{account})),\"OUT\"))",
    ],
    "yMax" => "100",
    "from" => $from,
    "until" => $until,
    "width" => $width,
    "height" => $height
  }
end

def generate_cc(host, vno, account)
  {
    "target" => [
      "cactiStyle(alias(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.gauge.InboundConnectedCalls-#{account}),\"IN\"))",
      "cactiStyle(alias(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.gauge.OutboundConnectedCalls-#{account}),\"OUT\"))",
      "cactiStyle(alias(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.gauge.{In,Out}boundConnectedCalls-#{account}),\"SUM\"))"
  ],
    "title" => "CC-#{account == "*" ? vno : account}",
    "from" => $from,
    "until" => $until,
    "width" => $width,
    "height" => $height
  }
end

def generate_cps(host, vno, account)
  {
    "target" => [
      "cactiStyle(alias(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.InboundCallAttempts-#{account}),\"IN\"))",
      "cactiStyle(alias(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.OutboundCallAttempts-#{account}),\"OUT\"))",
      "cactiStyle(alias(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.{In,Out}boundCallAttempts-#{account}),\"SUM\"))"
  ],
    "title" => "CPS-#{account == "*" ? vno : account}",
    "from" => $from,
    "until" => $until,
    "width" => $width,
    "height" => $height
  }
end

def generate_acd(host, vno, account)
  {
    "target" => [
      "cactiStyle(alias(divideSeries(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_duration.InboundCallDuration-#{account}), sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.InboundCallSuccess-#{account})),\"IN\"))",
      "cactiStyle(alias(divideSeries(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_duration.OutboundCallDuration-#{account}), sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_counter.OutboundCallSuccess-#{account})),\"OUT\"))"
  ],
    "title" => "ACD-#{account == "*" ? vno : account}",
    "from" => $from,
    "until" => $until,
    "width" => $width,
    "height" => $height
  }
end

def generate_smh(host, vno, account)
  {
    "target" => [
      "cactiStyle(alias(scale(hitcount(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_duration.InboundCallDuration-#{account}),\"1h\"),0.016667),\"IN\"))",
      "cactiStyle(alias(scale(hitcount(sum(scscf-2-maquette.GenericJMX.Sigal_Accounts-#{vno}.voip_duration.OutboundCallDuration-#{account}),\"1h\"),0.016667),\"OUT\"))"
  ],
    "title" => "SMH-#{account == "*" ? vno : account}",
    "from" => $from,
    "until" => $until,
    "width" => $width,
    "height" => $height
  }
end

#
# MAIN
#

cmd = CmdParse::CommandParser.new(true, true)
cmd.program_name = "voip_graph_generator"
cmd.program_version = [0, 0, 1]

cmd.add_command(CmdParse::HelpCommand::new, true)
cmd.add_command(CmdParse::VersionCommand::new)

cmd.options = CmdParse::OptionParserWrapper.new do |opt|
  opt.separator "Global options:"
  opt.on("-s", "--server SERVER", "Server running graphite-web (default: #{$server})") {|t| $server  = t }
  opt.on("-h", "--host HOST", "Host running the Karaf container (default: #{$host})") {|t| $host  = t }
  opt.on("-v", "--vno VNO", "Generate VNO graphs (default: #{$vno})") {|t| $vno  = t }
  opt.on("-a", "--account ACCOUNT", "Generate account/interco graphs (default: #{$account})") {|t| $account  = t }
  opt.on("-f", "--from FROM", "cf. --help (default: #{$from})") {|t| $from  = t }
  opt.on("-u", "--until UNTIL", "cf. --help (default: #{$until})") {|t| $until  = t }
  opt.on("-w", "--width WIDTH", "Width of generated graphs (default: #{$width})") {|t| $width  = t }
  opt.on("-e", "--height HEIGHT", "Height of generated graphs (default: #{$height})") {|t| $height  = t }
end

graph = CmdParse::Command::new('graph', false)
graph.short_desc = "Graph mode"
graph.description = "Generate one graph for an indicator"
graph.description << """
  Exemple :

  - Network Effectiveness Ratio for VNO #{$vno} :
    #{$PROGRAM_NAME} -v #{$vno} graph NER
  
  - Answer Seizure Ratio for Account 0991000001019 from VNO D200911200001 :
    #{$PROGRAM_NAME} -v D200911200001 -a 0991000001019 graph NER
  
#{$description}
"""

graph.set_execution_block do |args|
  if args.size > 0 && $indicators.include?(ind = args.first.upcase)
      puts "http://#{$server}/render?#{URI::encode(send(:"generate_#{ind.downcase}", $host, $vno, $account).map { |k,v| v.map { |w| "#{k}=#{w}" } }.flatten.join('&'))}"
  else
    graph.show_help
    puts "Indicator '#{args.first}' doesn't exist !"
  end
end

dashboard = CmdParse::Command::new('dashboard', false)
dashboard.short_desc = "Dashboard mode"
dashboard.description = "Generate dashboard containing all indicators"
dashboard.description << """
  Exemple :

  - Dashboard for VNO #{$vno} :
    #{$PROGRAM_NAME} -v #{$vno} dashboard
  
  - Dashboard for Account 0991000001019 from VNO D200911200001 :
    #{$PROGRAM_NAME} -v D200911200001 -a 0991000001019 dashboard
  
#{$description}
"""


dashboard.set_execution_block do |args|
  data = $indicators.map { |ind|
    send(:"generate_#{ind.downcase}", $host, $vno, $account)
  }

  puts JSON.pretty_generate data
end

cmd.add_command(graph)
cmd.add_command(dashboard)
cmd.parse
