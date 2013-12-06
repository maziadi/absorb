module Puppet::Parser::Functions

  newfunction(:str_not_empty, :type => :rvalue) do |args|
    !args[0].empty?
  end

end
