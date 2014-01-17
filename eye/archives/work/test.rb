def plugin_conf_generate(vno_id)
  puts "Generating collectd tail plugin's configuration for vno #{vno_id}"
  File.open('/home/ma.ziadi/mytest', 'a+') do |f|
    f.each do |line|
      line = line.chomp
      if(line=="bbb")then
        f.puts "\nInstance \"PCSCF-%s\"
    <Match>
     Regex \"%s::.*::REGISTER::\"
     DSType \"CounterInc\"
     Type \"counter\"
     Instance \"registers\"
    </Match>
    <Match>
     Regex \"%s::.*::INVITE::xxx\"
     DSType \"CounterInc\"
     Type \"counter\"
     Instance \"invites\"
    </Match>\n" % [vno_id.upcase, vno_id, vno_id]
      end
    end
  end
end
  plugin_conf_generate("d1234567890")
