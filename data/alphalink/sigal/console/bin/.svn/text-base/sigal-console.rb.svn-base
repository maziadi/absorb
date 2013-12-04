#!/usr/bin/env ruby

$: << File.join(File.dirname(File.dirname(__FILE__)), 'lib')

begin
  require 'rubygems'
  require 'cmdparse'
rescue LoadError => detail
  require 'cmdparse2'
end
require 'sigal'
require 'cdr'

DEFAULT_URL = ENV['STOMP_URL'] || 'stomp://operator:manager@127.0.0.1:61613'

$url    = DEFAULT_URL
$data   = {}

# send an update
def send_update(data, db_name, update_file)
  properties = {}
  template = Sigal::Template::new($url)
  begin
    if update_file
      properties = Sigal::read_file(update_file)
    end
    properties.merge!(data)
    template.update(db_name, properties) { |res|
      puts Sigal::message_to_yaml(res)
    }           
  ensure 
    template.close
  end  
end

def send_query(data, db_name) 
  template = Sigal::Template::new($url)
  begin
    template.query(db_name, data) { |res|
      puts Sigal::message_to_yaml(res)
    }           
  ensure 
    template.close
  end
end

def create_cmd(name, desc, parent = nil)
  cmd = CmdParse::Command::new(name.to_s, false)
  cmd.short_desc = desc
  cmd.description = desc
  parent.add_command(cmd) unless parent.nil?
  cmd.options = CmdParse::OptionParserWrapper::new do |opt|
    yield opt
  end
  cmd
end

# Creates an update option
def data_option(opt, sopt, lopt, llabel, help)
  opt.on("-#{sopt}", "--#{lopt} [#{llabel}]", help) { |value|
    case value.downcase
    when "false"
      value = false
    when "true"
      value = true
    end
    $data[lopt] = value
  }  
end

def required_option(name)
  raise "#{name} is a required argument" unless $data[name]
end

cmd = CmdParse::CommandParser::new(true, true)
cmd.program_name = "sigal-console.rb "
cmd.program_version = [0, 9, 0]

cmd.add_command(CmdParse::HelpCommand::new, true)
cmd.add_command(CmdParse::VersionCommand::new)

#
# Query command
#
query = CmdParse::Command::new('query', true)
query.short_desc = "Query a database"
query.description = "Query an AS database"
query.options = CmdParse::OptionParserWrapper::new do |opt|
  opt.on('-u', '--url [URL]', "Stomp broker URL") { |url| 
    $url = url
  }
end                    

create_cmd(:exdb, "Query EXDB", query) do |opt|
  data_option(opt, :a, :account_code, "Account code", "Account code")
end.set_execution_block do |args|
  required_option :account_code
  send_query($data, "EXDB")
end

create_cmd(:lidb, "Query LIDB", query) do |opt|
  data_option(opt, :a, :account_code, "Account code", "Account code")
  data_option(opt, :n, :number, "Number", "Number")
end.set_execution_block do |args|
  unless $data[:number] || $data[:account_code]
    raise "Either account_code or number is required"
  end
  send_query($data, "LIDB")
end

create_cmd(:npdb, "Query NPDB", query) do |opt|
  data_option(opt, :n, :number, "Number", "Number")
end.set_execution_block do |args|
  required_option :number
  send_query($data, "NPDB")
end

#
# Update command
#update
update = CmdParse::Command::new('update', true)
update.short_desc = "Update a database"
update.description = "Update an AS databases"


update.options = CmdParse::OptionParserWrapper::new do |opt|
  opt.on('-u', '--url [URL]', "Stomp broker URL") { |url| 
    $url = url
  }
#  opt.on('-n', '--number [NUMBER]', 
#         "Number to update the database with") { |number| 
#    $number = number
#  }
  opt.on('-f', '--file [filename]', 
         "File to update the database with") { |filename| 
    $update_file = filename
  }
#  data_option(opt, :r, :redirect_to, "NUMBER", "Number to redirect to")
#  data_option(opt, :p, :presentation, "VALUE", "presentation activation boolean switch")
#  data_option(opt, :i, :insee_code, "CODE", "INSEE code to update the database with")
#  data_option(opt, :s, :subscriber_number, "NUMBER", 
#    "Subscriber number to update the database with")
end                    

update.set_execution_block do |args|
  properties = {}
  raise "database argument is required" unless $db_name
  unless $update_file
    if "LIDB" == $db_name
      unless $account_code || $number
        raise "number or account_code argument is required" 
      end
      properties[$account_code ? :account_code : :number] = $account_code || $number
    else 
      raise "number argument is required" unless $number
    end
  end
end

create_cmd(:exdb, "Update EXDB", update) do |opt|
  data_option(opt, :a, :account_code, "Account code", "Account code")
end.set_execution_block do |args|
  send_update($data, "EXDB", $update_file)
end


test = CmdParse::Command::new('test', false)
test.short_desc = "Test"
test.description = "Test"
test.set_execution_block do |args|
  template = Sigal::Template::new($url)
  template.simple_topic_send
  sleep(1)
  template.close
end

cdr = CmdParse::Command::new('cdr',true)
cdr.short_desc = "CDR interactions"
cdr.description = "Interact with CDR"
cdr.options = CmdParse::OptionParserWrapper::new do |opt|
  opt.on('-u', '--url [URL]', "Stomp broker URL") { |url| 
    $url = url
  }
end

cdr.set_execution_block do |args|
  true
end

create_cmd(:listen, "CDR listener", cdr) do |opt|
end.set_execution_block do |args|
  template = Sigal::Template::new($url)
  template.listen_to_cdr(Sigal::Template::CdrTopicName) { |cdr|
    puts Sigal::message_to_yaml(cdr)
  }
  template.close
end

create_cmd(:inject, "CDR Injecter", cdr) do |opt|
  opt.on('-n', '--number [NUMBER OF MESSAGES]', 'Number of messages to send') { |nb|
    $number = nb.to_i
  }
end.set_execution_block do |args|
  $number ||= 1000
  template = Sigal::Template::new($url)
  begin
    Sigal::CdrInjecter::new(template).inject($number)
  ensure
    template.close
  end
end

create_cmd(:flush, "Flush CDR queue", cdr) do |opt|
  opt.on('-f', '--file [FILE]', "File to store CDR") { |file|
    $file = file
  }
end.set_execution_block do |args|
  require 'yaml'
  $file ||= "cdr.bin"
  template = Sigal::Template::new($url)
  count = 0
  begin
    fd = File.open($file, 'a+')
  rescue => res
    puts "Error: #{res}\n"
  end
  begin
    timeout(1) do
      template.listen_to_cdr(Sigal::Template::CdrQueueName) { |cdr|
        cdrsize = [cdr.serialize_to_string.size].pack("S")
        fd.write(cdrsize+cdr.serialize_to_string)
        puts(YAML::load(Sigal::message_to_yaml(cdr)).inspect) if $DEBUG
        count += 1
      }
    end
  rescue Timeout::Error => res
    puts "#{res} : No more CDR."
  end
  puts "#{count} CDR saved."
  fd.close
  template.close
end

create_cmd(:read, "Read CDR from file", cdr) do |opt|
  opt.on('-f', '--file [FILE]', "CDR file") { |file|
    $file = file
  }
end.set_execution_block do |args|
  require 'yaml'
  $file ||= "cdr.bin"
  begin
    fd = File.open($file, 'r')
  rescue => res
    puts "Error: #{res}\n"
  end
  begin
    while(!fd.eof?) do
      size = fd.read(2).unpack('S')[0].to_i
      cdr = Cdr::new.parse_from_string(fd.read(size))
      puts Sigal::message_to_yaml(cdr)
    end
  rescue => res
    puts "Error: #{res}\n"
  end
  fd.close
end

create_cmd(:alter, "Read & Write CDR from file to a file", cdr) do |opt|
  opt.on('-f', '--file [FILE]', "CDR file") { |file|
    $file = file
  }
  opt.on('-o', '--output [FILE]', "CDR file") { |file|
    $o_file = file
  }
end.set_execution_block do |args|
  require 'yaml'
  $file ||= "cdr.bin"
  begin
    fd = File.open($file, 'r')
    o_fd = File.open($o_file, 'w+')
  rescue => res
    puts "Error: #{res}\n"
  end
  begin
    icids = [
      "00a15639-cd0f-45e0-86d6-2b500aeec32b",
      "0a75f534-33ea-4446-9bde-2b50ea891337",
      "51877592-13b0-4353-a9a8-028742951c36",
      "d80ec838-52a1-494c-b5e6-aee30f329222",
      "eaac61d0-3371-433b-a217-08d816e5b066",
    ]
    while(!fd.eof?) do
      size = fd.read(2).unpack('S')[0].to_i
      cdr = Cdr::new.parse_from_string(fd.read(size))
      next unless icids.include?(cdr.icid)
      puts cdr.inspect
      cdr.calling.identity_number = "33662919514"
      cdr.calling.presentation = 2
      cdrsize = [cdr.serialize_to_string.size].pack("S")
      o_fd.write(cdrsize+cdr.serialize_to_string)
    end
  rescue => res
    puts "Error: #{res}\n"
  end
  fd.close
end

cmd.add_command(cdr)
cmd.add_command(query)
cmd.add_command(test)
cmd.add_command(update)
cmd.parse
