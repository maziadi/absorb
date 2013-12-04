require 'rubygems'
require 'stomp'
require 'timeout'
require 'yaml'                          
require 'sigal.pb'
include Com::Initsys::Sigal::Protocol

class SortedHash < Hash
    def each()
        ks = keys.sort_by { |k| k.to_s }
        ks.each { |k| yield(k, self[k]) }
    end
    def each_value()
        each { |k, v| yield(v) }
    end
end

module Sigal    
  def self::read_file(filename)
    YAML::load(File::new($update_file)).reject {|k,v| :status == k }
  end
  
  def self::message_to_yaml(res)
    res.fields.values.inject(SortedHash::new) { |h, field|
      if res.has_field?(field.name)
        value = res.send(field.name)
        value = Array::new(value) if value.kind_of? Protobuf::Field::FieldArray
        if field.name == :status
          code = ResponseStatus::ResponseStatusCode.name_by_value(value.code)
          h[field.name] = { 
            :code =>  code }
          if "OK" != code
            h[field.name][:message] = value.message
          end
        else 
          h[field.name] = value unless :version == field.name
        end
      end
      h
    }.to_yaml.gsub(/ !(map:|ruby\/).*/, '')
  end
        
  class Template
    TempDbQueueName = "/temp-queue/sigal.dbResponse"
    CdrTopicName    = "/topic/sigal.cdr.notification"
    CdrQueueName    = "/queue/sigal.cdr"
    DbQueueName = '/queue/sigal.db'
    
    def initialize(url, options = {})
      options[:timeout] = 10
      @options = options            
      # recompier de Stomp::Client en attendant que connection le supporte
      case url
      when /^stomp:\/\/([\w\.]+):(\d+)$/ # e.g. stomp://host:port
       # grabs the matching positions out of the regex which are stored as
       # $1 (host), $2 (port), etc
       @login = ''
       @passcode = ''
       @host = $1
       @port = $2.to_i
       @reliable = false
      when /^stomp:\/\/([\w\.]+):([\w\d]+)@([\d\w\.]+):(\d+)$/ # e.g. stomp://login:passcode@host:port
       @login = $1
       @passcode = $2
       @host = $3
       @port = $4.to_i
       @reliable = false
      end
      
      @conn = Stomp::Connection.new @login, @passcode, @host, @port, @reliable
      @conn.subscribe(TempDbQueueName, :ack => "auto")
    end

    def subscribe(name, ack = 'auto')
      @conn.subscribe(name, :ack => ack)
    end

    def receive(timeout = @options[:timeout])
      timeout(timeout) do
        @conn.receive
      end
    end

    def ack(id)
      @conn.ack(id)
    end

    def close
      @conn && @conn.disconnect
    end   
    
    def query(db_name, properties, &proc) 
      execute_request(db_name, properties, :QUERY, &proc)
    end

    def update(db_name, properties, &proc) 
      execute_request(db_name, properties, :UPDATE, &proc)
    end
    
    def listen_to_cdr(name)
      @conn.subscribe(name, :ack => 'auto')
      while true
        message = @conn.receive
        break if message.nil?
        yield Cdr::new.parse_from_string message.body
      end
    end
    
    def send(destination_name, msg, headers = {})
      if $DEBUG
        puts "Sending message with headers #{headers.inspect}"
      end
      @conn.send destination_name, msg, headers
    end                        
    
    private
    
    def execute_request(db_name, properties, method, &proc) 
      db_name = db_name.to_s.upcase
      send("#{DbQueueName}.#{method.to_s.downcase}", 
        make_message(db_name, method, properties), 
        :messageType => "#{db_name}.#{method}.REQUEST",
        :persistent => false,
        :expires => Time::now.to_i * 1000 + 5000,
        'reply-to' => TempDbQueueName)
      timeout(@options[:timeout]) do
        stomp_msg = @conn.receive
        msg = get_message_class(db_name, method, false)::new
        proc.call(msg.parse_from_string(stomp_msg.body))
      end
    end
    
    def get_message_class(db_name, method, is_request = true)
      suffix = is_request ? 'Request' : 'Response'
      eval "#{db_name.capitalize}#{method.to_s.capitalize}#{suffix}"
    end
    
    def make_message(db_name, method, properties)
      request = get_message_class(db_name, method)::new
      request.version = 1
      if properties.has_key? :codec
        properties[:codec] = properties[:codec].map { |c| Codec.class_eval(c.upcase)}
      end      
      properties.each { |key, value| 
        request.send("#{key}=", value)
      }
      puts Sigal::message_to_yaml(request)
      request.serialize_to_string
    end
  end
                 
end
