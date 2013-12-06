require 'yaml'
require 'tempfile'

INFRA_FILE = 'data/infrastructure.yaml'
VOIP_FILE = 'data/voip.yaml'
IP_FILE = 'data/ip.yaml'

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

module Model

    class Node
        include Enumerable
        attr_reader :name

        def initialize(name, hash)
            raise "hash must be a Hash" unless hash.kind_of? Hash
            @name = name
            @hash = hash
        end

        def [](name)
            @hash && @hash[name]
        end

        def children
            @hash
        end

        def each
            @hash.each_value { |value| yield value }
        end
        
        def find_hosts(pattern = '.*', params = {})
            pattern = Regexp::new(pattern) if pattern.kind_of? String
            node = params[:ancestor] ? find_group(params[:ancestor]) : self
            node ||= []
            node.collect { |child|
                case child
                    when Host then child
                    when HostGroup then child.find_hosts()
                end
            }.flatten.select { |host|
                host && host.name =~ pattern && 
                    (params[:where].nil? || eval(params[:where], host.create_binding)) 
            }
        end

        def find_groups(node = self)
            node.collect { |child|
                case child
                    when HostGroup then
                        find_groups(child) << child
                end
            }.flatten.compact
        end

        def find_group(pattern) 
            pattern = Regexp::new(pattern) if pattern.kind_of? String
            find_groups.find { |group| group.name =~ pattern }
        end 


        def find_host(name) 
            list = find_hosts("^#{name}\$")
            if list.size > 1
                raise "Plusieurs hotes retournes: '#{list.collect{ |h| h.name}.join(', ')}'"
            elsif list.size == 0
                raise "Aucun hote retourne"
            end
            list.first
        end 

        def create_binding
            b = binding
            [:type, :admin_name, :admin_addr, :admin_port, :backup, :check, :keys, :periph, :public_addr, :service_addr].each { |name| 
                eval "#{name} = self[:#{name}]", b
            }
            b
        end
    end

    class HostGroup < Node
        attr_reader :contacts
        def initialize(name, hash, contacts = [])
            super(name, hash)
            @contacts = contacts
        end
    end

    class Host < Node
        def to_s
            "Node: #{name}\n" + @hash.collect { |k, v| "  #{k}: #{v}" }.join("\n")
        end
    end

    class Infrastructure < Node
        def find_host(host_name, node = self)
            if node.kind_of?(Host) 
                node if node.name == host_name
            elsif node.kind_of?(Node) 
                res = node.collect { |child| 
                    find_host(host_name, child) 
                }.compact
                res == [] ? nil : res[0]
            end
        end

    end
    
    def self::load(file_name = INFRA_FILE)
        hash = YAML::load(File::new(file_name))
        Infrastructure::new('alphalink', self::parse('', hash).children)
    end

    private

    def self::parse(name, hash)
        if hash[:admin_addr] || hash[:admin_name]
            node = Host::new(name, hash)
        else
            children = {} 
            hash.each { |node_name, node_value|
                if node_value.kind_of? Hash
                    children[node_name] = self::parse(node_name, node_value)
                end
            }
            node = HostGroup::new(name, children, hash[:contacts]) 
        end
        node
    end

end

module VoipModel
    class Voip
        attr_reader :dids

        def initialize(dids)
            @dids = dids
        end

        def add(did)
            @dids.push(did)
        end

        def rem(didn)
            pattern = Regexp::new(didn)
            @dids.delete_if { |did| did.number =~ pattern }
        end

        def write(file_name = VOIP_FILE)
            f = Tempfile::new('voip.yaml')
            f.write(@dids.sort_by { |did| did.number }.collect { |did| did.to_yaml })
            f.close
            File::move(f.path, VOIP_FILE, true)
            f.close(true)
            
            #temp = `mktemp /tmp/voip.yaml.XXXXXX`
            #File::open(temp, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f|
            #    f.write(@dids.collect { |did| did.to_yaml })
            #}
            #File::move(temp, VOIP_FILE, true)
        end


        def find_dids(pattern = '.*', params = {})
            pattern = Regexp::new(pattern) if pattern.kind_of? String
            @dids.select { |did|
                did && did.number =~ pattern && 
                    (params[:where].nil? || eval(params[:where], did.create_binding)) 
                
           }.sort_by { |a| a.number }
        end
        def each
            @dids
        end
    end

    class Did 
        attr_reader :number
        attr_accessor :carrier, :client, :destination, :note, :validation, :account_code, :insee_code, :fax, :redirect_to
        def initialize(number, hash = {})
            @number = number
            hash.each_pair { |key, value|
                instance_variable_set("@#{key}", value) 
            }
        end
        
        def create_binding
            binding
        end

        def succ
            hash = Hash::new()
            instance_variables.collect { |name|
                hash[name[1..-1]] = instance_variable_get(name) if name != '@number'
            }
            Did.new((@number.to_i+1).to_s, hash)
        end

#        def <=>(other)
#            instance_variables.collect { |name|
#                return false if instance_variable_get(name) != other.instance_variable_get(name)
#            }
#            true
#        end

        def <=>(other)
            @number.to_i <=> other.number.to_i
        end

        def to_s
            "Did: #{@number}\n" + instance_variables.collect { |name|
                "  #{name[1..-1]}: #{instance_variable_get(name)}"
            }.join("\n") 
        end
       
        def to_yaml
            "'#{@number}':  \n" + instance_variables.collect { |name|
		value = instance_variable_get(name)	
                "  :#{name[1..-1]}: \"#{value}\"\n" unless (value.nil? || value.length == 0)
            }.join
        end
    end

    def self::load(file_name = VOIP_FILE)
        self::parse(YAML::load(File::new(file_name)))
    end

    private

    def self::parse(hash)
        dids = []
        hash.each_pair { |number, values|
            dids << Did::new(number, values) 
        }
        Voip::new(dids)
    end
end

module IpModel
    class Net
        attr_reader :inetnums

        def initialize(inetnums)
            @inetnums = inetnums
        end

        def find_inetnums(ips, params = {})
            ips.collect { |ip|
              ip = NetAddr::CIDR::create(ip)
              @inetnums.select { |inetnum|
                  inetnum && (ip.nil? || inetnum.subnet.contains?(ip)) && 
                      (params[:where].nil? || eval(params[:where], inetnum.create_binding)) 
              }  
           }.compact.flatten.uniq
        end
    end

    class Inetnum 
        attr_reader :range
        attr_accessor :netname, :descr, :country, :admin_c, :tech_c, :status, :mnt_by, :changed, :source, :remarks
        attr_accessor :customer

        def initialize(range, hash = {})
            @range = range
            hash.each_pair { |key, value|
                instance_variable_set("@#{key}", value) 
            }
            @country ||= 'FR'
            @admin_c ||= 'AL1446-RIPE'
            @tech_c  ||= 'AL1446-RIPE'
            @status ||= 'ASSIGNED PA'
            @mnt_by ||= 'ALPHALINK-MNT'
            @changed ||= []
            @source ||= 'RIPE'

            if @changed.kind_of? String
              @changed = [ @changed ]
            end
            @subnet = get_subnet
        end
      
        def get_subnet
            first, last = @range.split(' - ')
            net = nil
            9.times { |i|
                net = NetAddr::CIDR.create("#{first}/#{30 - i}")
                break if net.contains?(last)
            }
            raise "Impossible de trouver le reseau pour #{@range}" unless net.contains?(last)
            net 
        end
 
        def subnet
            @subnet
        end
 
        def create_binding
            binding
        end

        def size
            @subnet.size
        end

        def <=>(other)
            raise "Todo"
            @range.to_i <=> other.number.to_i
        end

        def to_s
            # TODO: gerer ca avec un attr_accessor modifie
            names = ['netname', 'descr', 'country', 'admin_c', 'tech_c', 'status', 'mnt_by', 'changed', 'source', 'remarks']
            
            (["inetnum: #{@range}"] + names.collect { |name|
                value = instance_variable_get("@" + name)
                value = [ value ] unless value.kind_of? Array
                value.collect { |val| 
                  "#{name.gsub(/_/, '-')}: #{val}" unless val.nil? || name == "range" 
                }
            }).flatten.compact.join("\n")
        end
    end

    def self::load(file_name = IP_FILE)
        self::parse(YAML::load(File::new(file_name)))
    end

    private

    def self::parse(hash)
        Net::new(_parse(hash))
    end

    def self::_parse(hash)
        inetnums = []
        hash.each_pair { |range, values|
            case range
            when Symbol then
            when String then
                values.reject! { |key, value|
                    if value.kind_of? Hash
                        inetnums.concat(self::_parse({ key => value }))
                        true
                    else
                        false
                    end
                }
                inetnums << Inetnum::new(range, values)
            else
                raise ArgumentError, "Incorrect object type in YAML: #{range.class}"
            end
        }
        inetnums
    end
end

module ClientModel
    class Register
        attr_reader :clients

        def initialize(clients)
            @clients = clients
        end

        def find_clients(pattern = '.*', params = {})
            pattern = Regexp::new(pattern) if pattern.kind_of? String
            @clients.select { |client|
                client && client.range =~ pattern &&
                    (params[:where].nil? || eval(params[:where], client.create_binding))
            }
        end
    end

    class Client
        attr_reader :name
        attr_accessor :label

        def initialize(range, label = nil) 
            @range, @label = range, label
        end

        def create_binding
            binding
        end

        def <=>(other)
            name <=> other.name
        end

        def to_s
            "#{name}" + (label ? " (#{label})" : "")
        end
    end

    def self::load(file_name = IP_FILE)
        self::parse(YAML::load(File::new(file_name)))
    end

    private

    def self::parse(hash)
        Net::new(_parse(hash))
    end

    def self::_parse(hash)
        clients = []
        hash.each_pair { |range, values|
            case range
            when Symbol then
            when String then
                values.reject! { |key, value|
                    if value.kind_of? Hash
                        inetnums.concat(self::_parse({ key => value }))
                        true
                    else
                        false
                    end
                }
                inetnums << Inetnum::new(range, values)
            else
                raise ArgumentError, "Incorrect object type in YAML: #{range.class}"
            end
        }
        clients
    end
end
