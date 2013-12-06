require 'augeas'

class AugEditor
  attr_accessor :aug
  @@aug_persist = nil
  def initialize 
    if @@aug_persist.nil?
      @@aug_persist = Augeas::open($root_dir,nil,Augeas::NO_MODL_AUTOLOAD)
      @aug = @@aug_persist
    else
      @aug = @@aug_persist
    end
    @aug.load!
  end
  def find_first_free_id(path, id = 1, exclude = nil)
    if @aug.match("#{path}").size > 0
      values = @aug.match("#{path}").map do |value|
        @aug.get("#{value}").to_i
      end.sort
      if exclude
        free_values = Array(id..values.last) - values -exclude
      else
        free_values = Array(id..values.last) - values
      end
      if free_values.size > 0
        id = free_values.first
      else
        id = values.last + 1
      end
    else
      id = 1
    end
    id
  end
	def close()
		@aug.save()
    error = false
    @aug.match("/augeas//error").each{|err|
        error = true
        STDERR.puts "#{err} : #{@aug.get(err)}"
        @aug.match("#{err}/*").each{|a| STDERR.puts "#{a} : #{@aug.get(a)}" }
    }
    
    raise "Impossible to save file" if error
		@aug.close()
    @@aug_persist = nil
	end
  def save
		@aug.save()
    error = false
    @aug.match("/augeas//error").each{|err|
        error = true
        STDERR.puts "#{err} : #{@aug.get(err)}"
        @aug.match("#{err}/*").each{|a| STDERR.puts "#{a} : #{@aug.get(a)}" }
    }
    
    raise "Impossible to save file" if error
  end
end
