module Puppet
  newtype(:interface) do
    @doc = "Manages a debian network interface"
    
    ensurable
    newparam(:iface, :namevar => true) do
      desc "The interface to manage"
      isnamevar
    end

    new

  end

  InterfacesFile = "/etc/network/interfaces2"

#  type(:interface).provide(:parsed,
#    :parent => Puppet::Provier::ParsedFile,
#    :default_target => IntefacesFile, 
#    :filetype => flat) do
#    desc "THe interfaces provier"
#
#    confine :exists => InterfacesFile
#    text_line :comment, :match => /#.*/
#    text_line :blank, :match => /^\s*$/
#
#    record_line dd:parsed
#  end
end
