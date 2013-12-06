task :init do
end

task :hostname do
   raise "hostname must be defined" unless $hostname = ENV["hostname"]
end

def ssh( server, cmd )
    system "echo #{server}; ssh #{server} #{cmd}"
end

def hosts
    @nodes = ["xen-1-cbv1", "xen-1-ext1", "xen-2-cbv1", "xen-2-ext1", "xen-3-cbv1", "xen-3-ext1"]

end
def all(cmd)
    hosts
    @nodes.each { |host| ssh(host, cmd) }
end

def state
    "crm_mon -1"
end

desc """Description"""
task :default => :init do
    puts
    puts "Ce rake file permet d'effectuer differentes"
    puts "operations sur le cluster vserver"
    puts
    sh "rake -f #{__FILE__} -T"
    puts
end

desc """Afficher l'espace disponible sur les san """
task :diskspace => :init do
    san = %w( san-1-cbv1 san-1-cbv2 ) 
    san.each do |host|
        ssh( host, 'vgs && uptime' )
    end
end

desc """Verification de l'etat des domUs du cluster"""
task :uptime => :init do
    all('uptime')
end

desc """xm list sur tous les Dom0"""
task :xmlist => [:init] do
    all("xm list")
end

desc """creation fichier suivi data/vservers_localization"
task :localize => :init do
  require 'open3'
  FILE = "data/vservers_localization"
  hosts
  puts "updating #{FILE}"
  open(FILE, "w") do |f|
    @nodes.each do |node|
      f.write("### #{node} ###\n")
      stdin, stdout,stderr = Open3.popen3("ssh #{node} xm list")
      lines = stdout.readlines
      lines.each do |l| 
        host = (l.split(" "))
        vserver = host[0] if l  !~ /Name|Domain/
        f.write("#{vserver}\n") if vserver != nil
      end
      f.write("\n")
    end
  end
  puts "done"
end


desc """Verifier l'etat du cluster """
task :health => :init do
    ssh( "xen-2-cbv1", state )
end

desc """Verifier sur quels xen sont montes les targets iscsi"""
task :mount_target => [:hostname, :init] do
  all("iscsiadm -m session | grep #{$hostname}")
end
# grep san-1-cbv2 haresources | awk '{print $NF}' | perl -ne 'print m/iscsi_target::(\d{2})/'

desc """Decouverte des targets depuis les XENs """
task :targets => :init do
    all( 'iscsiadm -m discovery -t st -p 169.254.62.101 > /dev/null 2>&1' ) 
end

desc """puppetd sur le cluster complet"""
task :puppet_xen => :init do
  all( 'puppetd --test' )
end
