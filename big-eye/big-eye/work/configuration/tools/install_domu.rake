task :init do
  raise "hostname must be defined" unless $hostname = ENV["hostname"]
  raise "ip must be defined" unless $ip = ENV["ip"]

  $distrib = ENV["distrib"] || "lenny"
  $puppetmaster = ENV["puppetmaster"] || "gold"
  $server = "maquette-1-por1"
  $img_dir = "/data/images"
  $cfg_dir = "/etc/xen"
  $source = "source-#{$distrib}"
end

def ssh( server, cmd )
    system "ssh #{server} '#{cmd}'"
    if($? != 0)
      sleep 5
      ssh( server, cmd )
    end
end

desc """Description"""
task :default => :init do
    puts
    puts "Ce rakefile permet d'installer une machine"
    puts "virtuelle sur maquette-1-por1"
    puts
    sh "rake -f #{__FILE__} -T"
    puts
end

desc """creation du fichier image"""
task :create => :init do
  def create_img( hostname )
    "cp #{$cfg_dir}/#{$source}.cfg #{$cfg_dir}/#{hostname}.cfg;" +
    "ln -s #{$cfg_dir}/#{hostname}.cfg #{$cfg_dir}/auto/#{hostname}.cfg > /dev/null 2>&1;" +
    "sed -i -e 's/#{$source}/#{hostname}/' #{$cfg_dir}/#{hostname}.cfg;" +
    "cp #{$img_dir}/#{$source}.img #{$img_dir}/#{hostname}.img;" 
  end
  puts "Create #{$hostname}.img on maquette-1-por1"
  ssh( $server, create_img( $hostname ) )
end

desc """start host"""
task :start => :init do
  def start_host( hostname )
    "xm create #{$cfg_dir}/#{hostname}.cfg"
  end
  sleep 15
  ssh( $server, start_host( $hostname ) )
  sleep 30
end

desc """configure new host (hostname, network)"
task :configure => [:init] do
  def config_img( hostname, ip )
    "sed -i -e 's/#{$source}/#{hostname}/' /etc/hostname;" +
    "sed -i -e 's/10.2.44.1./#{$ip}/' /etc/network/interfaces;" +
    "rm /etc/puppet/puppet.conf; rm -r /var/lib/puppet/ssl/*;" +
    "rm /etc/ssh/ssh_host_*; dpkg-reconfigure openssh-server;" +
    "reboot"
  end
  ssh( $source, config_img( $hostname, $ip ) )
  sleep 30
end

desc """pupettize"""
task :puppetize => :init do
  def known_host( hostname )
    tmp_file = "/tmp/#{hostname}"
    ssh_options = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=#{tmp_file}"
    system "ssh #{hostname} #{ssh_options} uptime"
    system "cat /tmp/#{hostname} >> ~/.ssh/known_hosts"
    system "rm #{tmp_file}"
  end
  
  known_host ( $hostname )
  if $distrib == "lenny"
    sh "./tools/puppetize -h #{$hostname} -p #{$puppetmaster} -t"
  else
    sh "./tools/puppetize -h #{$hostname} -f etch -p #{$puppetmaster} -t"
  end
end

desc """Install"""
task :install => [:create, :start, :configure, :puppetize] do
  puts "#{$hostname} is ready"
end
