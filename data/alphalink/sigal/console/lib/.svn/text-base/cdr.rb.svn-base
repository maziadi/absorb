require 'stomp'
require 'sigal.pb'

include Com::Initsys::Sigal::Protocol

module Sigal
  class CdrInjecter
  
    def initialize(template)
      @template = template
    end
  
    def inject(nb = 1000)
      msg = Cdr::new()
      msg.version = 1
      msg.complete = false
      msg.node = "test-node"
      msg.icid = ""
      nb.times {
        @template.send("/queue/sigal.cdr", msg.serialize_to_string, 
          :persistent => true)
      }
    end
  end
end