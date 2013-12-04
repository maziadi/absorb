module Puppet::Parser::Functions

  newfunction(:get_keys, :type => :rvalue) do |args|
    if args.nil? || args[0].is_a?(Hash)
      Puppet.warning "get_keys takes one argument, the input hash"
      nil
    else
      args[0].keys
    end
  end

end
