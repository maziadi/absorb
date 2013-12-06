#!/usr/bin/env ruby

ROOT_OID='.1.3.6.1.4.1.34026.1'
FILE="/proc/net/dev"
@nextoidreq=false

def get_args(args)
  while args.size>0 
    a=args.shift
    if a=="-n" 
      @nextoidreq=true
    else request=a    
    end
  end
  return request
end


class Mib_interfaces
	def grab_interfaces_data
    lines=[]
    i=0
    begin
      fd=File.open(FILE)
    rescue 
      exit 1
    end
     
    while !fd.eof?
      i+=1
      if i>2                          #ignore first two lines
        lines.push(fd.readline)
      else
        fd.readline
      end
    end
    fd.close
  
    tab = lines.collect { |line| line.strip.chomp.split(/[: ][: ]*/) }
    tab=tab.transpose
    @nbif=tab[0].size
    tab = [ (1..@nbif).collect { |d| d } ] +  tab

    @htab={}
    x=0
    tab.each {|line|
      x+=1
      y=0
      line.each {|item|
      y+=1
      index=x.to_s+'.'+y.to_s
      @htab[ROOT_OID+'.'+index]=item
      }
    }
#     p @htab
  end

    def print_oid(oid)
      if @htab[oid].nil?
        print "ack ... #{oid}\n" 
        return 1
      end

      print "#{oid}\n"
      case oid.split('.')[9] 
        when "1": print "integer\n"
        when "2": print "string\n"
        else      print "counter32\n"
      end
      print "#{@htab[oid]}\n"

    end

    def next_oid(oid)
      oids=@htab.keys.sort { |x,y| x.split('.')[9].to_i*(@nbif+1)+x.split('.')[10].to_i <=> y.split('.')[9].to_i*(@nbif+1)+y.split('.')[10].to_i }

      if oid==ROOT_OID
        return oids[0]
      end
      
      if oid.split('.')[10] == nil                                                #occurance control
        return ROOT_OID+"."+oid.split('.')[9]+".1"
      end

      if oids.index(oid)==nil 
        return 1 
      end

      return oids[oids.index(oid)+1]  
    end
end

request=get_args(ARGV)

mib=Mib_interfaces.new
mib.grab_interfaces_data
if @nextoidreq
  request=mib.next_oid(request)
end
mib.print_oid(request)
