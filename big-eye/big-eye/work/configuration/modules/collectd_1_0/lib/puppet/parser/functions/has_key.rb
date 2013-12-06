module Puppet::Parser::Functions

  newfunction(:has_key, :type => :rvalue) do |args|
    if args.nil? || (!args[0].is_a?(String) && !args[1].is_a?(Hash))
      Puppet.warning "has_key takes two argumenta, string key name and hash containing the string."
      nil
    else
      args[1].has_key?(args[0])
    end
  end

end
