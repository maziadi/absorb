#!/usr/bin/env ruby

begin
    require 'cmdparse2'
rescue LoadError => detail
    require 'rubygems'
    require 'cmdparse'
end
require 'benchmark'

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/libalpha.rb'
else
  require_relative 'libalpha'
end

def smtp_opts(opt)
    opt.on('-f', '--from FROM_ADDR', "Mail 'FROM' address") { |from| 
        $from = from
    }
    opt.on('-t', '--to TO_ADDR', "Mail 'To' address") { |to|
        $to = to
    }
    opt.on('-h', '--host SMTP_HOST', "Hostname or IP address the message is sent to") { |host|
        $smtp_host = host
    }
    imap_opts(opt)
    opt.on('-d', '--delay DELAY', "Delay to wait before checking the mailbox") { |delay|
        $delay = delay.to_i
    }
end

def imap_opts(opt)
    opt.on('-i', '--imap_host IMAP_HOST', 
        "Hostname or IP address of the mailbox server (defaults to SMTP_HOST)") { |host|
        $imap_host = host
    }
    opt.on('-u', '--username USERNAME', "IMAP username") { |username|
        $imap_username = username
    }
    opt.on('-P', '--password PASSWORD', "IMAP password") { |password|
        $imap_password = password
    }
    opt.on('-p', '--port IMAP_PORT', "IMAP port (defaults to 143)") { |port|
        $imap_port = port
    }
end

cmd = CmdParse::CommandParser::new(true, true)
cmd.program_name = "check.rb"
cmd.program_version = [0, 0, 1] 

cmd.add_command(CmdParse::HelpCommand::new, true)
cmd.add_command(CmdParse::VersionCommand::new)

spam = CmdParse::Command::new('spam', false)
spam.short_desc = "Check spam"
spam.description = "Check SPAM by bla"
spam.description << "BLABLA"
spam.options = CmdParse::OptionParserWrapper::new do |opt|
    smtp_opts(opt)
end
spam.set_execution_block do |args|
    require 'tmail'
    require 'net/smtp'
    require 'net/imap'

    $from ||= 'spam-test@alphalink.fr' 
    $smtp_host ||= '217.15.80.11'
    $delay ||= 30
    $imap_host ||= $smtp_host
    $imap_username ||= nil
    $imap_password ||= nil

    subject = "SPAM TEST #{(rand * 1000000000).ceil}"
    send_mail($smtp_host, $to, $from, subject, 
        'XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X')

    if $imap_username and $imap_password \
        and check_imap($imap_host, $imap_username, $imap_password, subject, $delay)
        puts "Le SPAM '#{subject}' est passe au travers du filtre" 
        exit(-2)
    end
end

mail = CmdParse::Command::new('mail', false)
mail.short_desc = "Check mail"
mail.description = "Check mail by bla"
mail.description << """
""" 
mail.options = CmdParse::OptionParserWrapper::new do |opt|
    smtp_opts(opt)
    opt.on('-b', '--bulk SIZE', "size of a bulk mail to send") { |size|
        $body = "a" * size.to_i
    }
end
mail.set_execution_block do |args|
    require 'tmail'
    require 'net/smtp'
    require 'net/imap'

    $from ||= 'mail-test@alphalink.fr' 
    $smtp_host ||= '217.15.80.11'
    $delay ||= 30
    $imap_host ||= $smtp_host
    $imap_username ||= nil
    $imap_password ||= nil
    $body ||= 'Test body'

    subject = "MAIL TEST #{(rand * 1000000000).ceil}"
    send_mail($smtp_host, $to, $from, subject, $body)

    if $imap_username and $imap_password \
        and !check_imap($imap_host, $imap_username, $imap_password, subject, $delay)
        puts "Le mail '#{subject}' n'est passe au travers du filtre" 
        exit(-2)
    end
end

imap = CmdParse::Command::new('imap', false)
imap.short_desc = "Check imap"
imap.description = "Check imap by bla"
imap.description << """
""" 
imap.options = CmdParse::OptionParserWrapper::new do |opt|
    imap_opts(opt)
end
imap.set_execution_block do |args|
    require 'net/imap'
    if $imap_host.nil?
        puts "-h, --host is mandatory"
        exit(-1)
    end
    $imap_username ||= nil
    $imap_password ||= nil
    $imap_port ||= 143

    puts "#{$imap_host} #{$imap_port}"
    begin_time = Time::now
    puts "Connecting..."
    imap = Net::IMAP.new($imap_host, $imap_port)
    puts "Authenticating..."
    imap.authenticate('LOGIN', $imap_username, $imap_password)
    puts "Selecting INBOX..."
    imap.select('INBOX')
    puts "Searching RECENT mails..."
    imap.search(["RECENT"]).each do |message_id|
        envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
        puts "#{message_id}: '#{envelope.subject}'"
    end
end

proxy = CmdParse::Command::new('proxy', false)
proxy.short_desc = "Check proxy"
proxy.description = "Check proxy by bla"
proxy.description << """
Virus addresses:
 * http://www.eicar.org/download/eicar.com
 * http://www.eicar.org/download/eicar.com.txt
 * http://www.eicar.org/download/eicar_com.zip
 * http://www.eicar.org/download/eicarcom2.zip
"""
proxy.options = CmdParse::OptionParserWrapper::new do |opt|
    opt.on('-h', '--host PROXY_HOST', "Proxy host name or address") { |host| 
        $proxy_host = host
    }
    opt.on('-p', '--port PROXY_PORT', "Proxy port (defaults to 3128)") { |port| 
        $proxy_port = port.to_i
    }
    opt.on('-u', '--username USERNAME', "Proxy username") { |username|
        $proxy_username = username
    }
    opt.on('-P', '--password PASSWORD', "Proxy password") { |password|
        $proxy_password = password
    }
    opt.on('-v', '--verbose', "Be verbose: display the body") { |verbose|
        $verbose = true
    }
end

 def fetch(uri_str, limit = 10)
      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      response = Net::HTTP.get_response(URI.parse(uri_str))
      case response
      when Net::HTTPSuccess     then response
      when Net::HTTPRedirection then fetch(response['location'], limit - 1)
      else
        response.error!
      end
    end

proxy.set_execution_block do |args|
    require 'net/http'
    require 'net/https'
    require 'uri'

    if $proxy_host.nil?
        puts "-h, --host is mandatory"
        exit(-1)
    end
    $verbose ||= false
    $proxy_port ||= 3128
    $proxy_username ||= nil
    $proxy_password ||= nil
    url = args.size > 0 ? args[0] : 'http://www.google.fr/'
    url = URI.parse(url)

    puts "Connecting to '#{url}'..."
    if url.scheme == 'https'
      http = Net::HTTP::new(url.host, url.port, $proxy_host, $proxy_port, $proxy_username, $proxy_password)
      http.use_ssl = true
    else
      http = Net::HTTP::new(url.host, url.port, $proxy_host, $proxy_port, $proxy_username, $proxy_password)
    end
    res, time = nil
    alltime = Benchmark::measure {
    time = http.start {|http|
        Benchmark::measure {
            res = http.get((url.path.nil? || url.path == "") ? "/" : url.path)
        }
    }
    } 
    if res.kind_of? Net::HTTPOK
        puts res.body if $verbose
        puts("Got '%s' in %.2fs / %.2fs" % [url.to_s, time.real, alltime.real]) 
    else
        puts "Impossible de se connecter a '#{url}' au travers de '#{$proxy_host}:#{$proxy_port}'"
        puts "La reponse est: #{res.code} #{res.message}"
        exit(-2)
    end
end

http = CmdParse::Command::new('http', false)
http.short_desc = "Check http"
http.description = "Check http by bla"
http.description << """
Virus addresses:
 * http://www.eicar.org/download/eicar.com
 * http://www.eicar.org/download/eicar.com.txt
 * http://www.eicar.org/download/eicar_com.zip
 * http://www.eicar.org/download/eicarcom2.zip
"""
http.options = CmdParse::OptionParserWrapper::new do |opt|
    opt.on('-h', '--host HTTP_HOST', "Host or address to connect to") { |host| 
        $http_host = host
    }
    opt.on('-a', '--address HTTP_HOST', "Host or address to connect to") { |address| 
        $http_address = address
    }
    opt.on('-p', '--port HTTP_PORT', "Port to connect to (defaults to 80)") { |port| 
        $http_port = port.to_i
    }
    opt.on('-u', '--uri URI', "URI to request (defaults to '/')") { |uri|
        $http_uri = uri
    }
    opt.on('-v', '--verbose', "Be verbose: display the body") { |verbose|
        $verbose = true
    }
end
http.set_execution_block do |args|
    require 'net/http'
    require 'uri'

    if $http_host.nil?
        puts "-h, --host is mandatory"
        exit(-1)
    end
    $verbose ||= false
    $http_port ||= 80
    $http_uri ||= '/' 
    $http_password ||= nil
    $http_address ||= $http_host
    url = "http://#{$http_host}:#{$http_port}/#{$http_uri}"
    puts "Connexion a '#{url}'..."
    res, time = nil
    alltime = Benchmark::measure {
    time = Net::HTTP::start($http_address, $http_port) {|http|
        Benchmark::measure {
            res = http.get($http_uri, {'Host' => $http_host})
        }
    }
    } 
    if res.kind_of? Net::HTTPOK
        puts res.body if $verbose
        puts("Got '%s' in %.2fs / %.2fs" % [url.to_s, time.real, alltime.real]) 
    else
        puts "Impossible de se connecter a '#{url}'"
        puts "La reponse est: #{res.code} #{res.message}"
        exit(-2)
    end
end

cmd.add_command(mail)
cmd.add_command(imap)
cmd.add_command(spam)
cmd.add_command(proxy)
cmd.add_command(http)
cmd.parse



