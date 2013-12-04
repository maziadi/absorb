#!/usr/bin/env ruby

# Ce script sert pour envoyer un colis.
# Il genere le fichier pdf, et envoie le mail dans avisdexpedition.

require 'date'
begin 
  require 'rubygems' 
rescue LoadError => error
  puts error
  abort "For this script you must install ruby gems (sudo aptitude search rubygems)" 
end
begin
  require 'erb'      
rescue LoadError  => error
  puts error
  abort "For this script you must install gem erb   (sudo gem install erb)"
end
begin 
  require 'rods'
rescue LoadError  => error
  puts error
  abort "For this script you must install gem rods  (sudo gem install rods zip)"
end
begin 
  require 'zip'
rescue LoadError => error
  puts error
  abort "For this script you must install gem zip  (sudo gem install zip)"
end
begin 
  require 'net/smtp' 
rescue LoadError => error
  puts error
  abort "For this script you must install ruby gems (sudo gem install net/smtp)"
end

WEIGHT = {"isr403" => 1.7, "isr405" => 1.7, "isr407" => 1.7, "isr803" => 3.5, "isr804" => 3.5, "isr806" => 3.5, "isr808" => 3.5, "isr9000" => 10.5, "speedtouch" => 0.6, "speedtouch-BIVC" => 0.9, "comtrend" => 0.9, "cisco" => 3.5, "thomson-efm" => 0.9}

SERVER_SMTP = 'mail.admin.alphalink.fr'
USER = ENV['HOME'].split("/")[2]
MAIL_FROM = USER+'@alphalink.fr'
MAIL_TO   = 'avisdexpedition@alphalink.fr'
#MAIL_TO   = 'n.barbier@alphalink.fr'
#MAIL_TO   = 'm.vanco@alphalink.fr'             # for debuging
TMP_PATH = '/tmp/'
NAS_PATH = ENV['HOME']+'/nas/technique/Production/'
LIST_MATERIEL_OOCALC  = NAS_PATH+'Suivi_expedition_materiel.ods'
SCRIPT_PATH = File.dirname(__FILE__)+"/"
RESURCES_PATH = 'resources/'
TEMPLATE_FICHE_CONFORMITE = SCRIPT_PATH+RESURCES_PATH+'fiche_conformite_tex.erb'
TEMPLATE_MAIL_AVISEXPEDITION = SCRIPT_PATH+RESURCES_PATH+'mail_avisexpedition.erb'
TEMPLATE_MAIL_AVISEXPEDITION_CLIENT = SCRIPT_PATH+RESURCES_PATH+'mail_avisexpedition_client.erb'
OOCALC_TABLE_WIDTH = 24


# Overload for quiet INFO messages.
class Rods
  def tell(message)
  end
end

def print_usage
    puts "Ce script sert a envoyer le colis. Les colis se trouvent dans le fichier Suivi_expedition_materiel.ods sur le NASr, répertoire production"
    puts "Remplissez ce fichier avec un nouvel ID et ensuite lancez ce script"
    puts "Usage: send_colis -id <ID_COLIS> [-rec <NUMERO RECEPISE>]"
    abort 
end

def parse_arguments(args)
  $DEBUG = (ARGV.delete '--debug') ? true : false
  puts "Entering debug mode..." if $DEBUG

  position = args.index("-id")
  id = args[position+1] if not position.nil?
  id = id.to_i
  print_usage if id == nil or id == 0 

  position = args.index("-rec")
  rec = args[position+1] if not position.nil?
  rec = rec.to_i
  arguments = {:id => id, :recepise => rec}
end


class Colis
  attr_reader :package_items, :weight 
  attr_reader :id_colis, :num_recepise, :commande, :client, :tache, :addr_client, :addr_attention, :addr_rue, :addr_codepostale, :addr_ville, :addr_tel

  # this method return array of items for one package 
  def read_oocalc(id_colis) 
    row = 2
    colis_number = 0
    one_materiel = Array::new
    @package_items = Array::new

    sheet = Rods.new(LIST_MATERIEL_OOCALC)
    until colis_number == nil do                   # read all item in file
      row += 1                                     # dont read first two label line
      colis_number, = sheet.readCell(row,1)        # look for what package is this line
      if colis_number.to_i == id_colis then        # if row is for my package, then
        for i in 1..OOCALC_TABLE_WIDTH do 
          item, = sheet.readCell(row,i)            # read all of items for product
          one_materiel << item
        end 
        @package_items << one_materiel
        one_materiel = []
      end
    end
    return @package_items
  end

  def get_weight
    @weight = 0
    @package_items.each {|mat|
      mat = mat[11].upcase
      case mat
        when "ISR403"      then @weight += WEIGHT["isr403"]
        when "ISR405"      then @weight += WEIGHT["isr405"]
        when "ISR407"      then @weight += WEIGHT["isr407"]
        when "ISR804"      then @weight += WEIGHT["isr804"]
        when "ISR806"      then @weight += WEIGHT["isr806"]
        when "ISR808"      then @weight += WEIGHT["isr808"]
        when "ISR9000"     then @weight += WEIGHT["isr9000"]
        when "COMTREND"    then @weight += WEIGHT["comtrend"]
        when "SPEEDTOUCH"  then @weight += WEIGHT["speedtouch"]
        when "SPEEDTOUCH-BIVC"  then @weight += WEIGHT["speedtouch-BIVC"]
        when "CISCO"       then @weight += WEIGHT["cisco"]
        when "THOMSON-EFM" then @weight += WEIGHT["thomson-efm"]
      end
    }
    return @weight
  end

  def get_contents_packet
    @contenu = Hash::new(0)

    @id_colis         = @package_items[0][0]
    @commande         = @package_items[0][1]
    @tache            = @package_items[0][3]
    @client           = @package_items[0][4]
    @addr_client      = @package_items[0][5]
    @addr_attention   = @package_items[0][6]
    @addr_rue         = @package_items[0][7]
    @addr_codepostale = @package_items[0][8]
    @addr_ville       = @package_items[0][9]
    @addr_tel         = @package_items[0][10]

    @package_items.each {|mat| 
      @contenu["alimentation"] += mat[18].to_i   #number of alimentations
      @contenu["cordonalim"]   += mat[19].to_i   #number of cordon alim
      @contenu["cabledroit"]   += mat[20].to_i   #number of cable droit
      @contenu["cablecroise"]  += mat[21].to_i   #number of cable croise
      @contenu["cableserie"]   += mat[22].to_i   #number of cable serie
      @contenu["autres"]       += mat[23].to_i   #number of others
      }

      @contenu_type = WEIGHT.dup                                 # copy all types of materiels
      @contenu_type.each {|key, value| @contenu_type[key] = 0}   # set number of materiel 0

      @package_items.each {|mat|
      mat = mat[11].upcase
      case mat
        when "ISR403"      then @contenu_type["isr403"] += 1
        when "ISR405"      then @contenu_type["isr405"] += 1
        when "ISR407"      then @contenu_type["isr407"] += 1
        when "ISR804"      then @contenu_type["isr804"] += 1
        when "ISR806"      then @contenu_type["isr806"] += 1
        when "ISR808"      then @contenu_type["isr808"] += 1
        when "ISR9000"     then @contenu_type["isr9000"] += 1
        when "COMTREND"    then @contenu_type["comtrend"] += 1
        when "SPEEDTOUCH"  then @contenu_type["speedtouch"] += 1
        when "SPEEDTOUCH-BIVC"  then @contenu_type["speedtouch-BIVC"] += 1
        when "CISCO"       then @contenu_type["cisco"] += 1
        when "THOMSON-EFM" then @contenu_type["thomson-efm"] += 1 
                               @EFM = true
      end
    }
    @contenu_type.delete_if {|materiel, nombre| nombre == 0 }    #delete materiel who isn't in package
  end

  def initialize(id_colis, num_recepise = nil)
    @date = DateTime.now.strftime('%d/%m/%Y')
    @num_recepise = num_recepise

    table = read_oocalc(id_colis)
    if table.size == 0 then
      abort "Il n'y a pas de colis avec l'ID: #{id_colis} dans Suivi_expedition_materiel.ods. J'abandone. "
    end

    get_contents_packet
    get_weight
    @filename_scheme = "#{@client}-#{@commande}"
    @template = ERB.new(File.read(TEMPLATE_FICHE_CONFORMITE))
  end

  def fill
    @template_filled = @template.result(binding)
  end

  def create_pdf
    File.open(TMP_PATH+@filename_scheme+".tex",'w') {|f| f.write(@template_filled)}
    puts "Creating conformity report..."
     # executed_code = system "pdflatex -output-format pdf -output-directory #{TMP_PATH} '#{TMP_PATH}#{@filename_scheme}'.tex" if $DEBUG
      executed_code = system "pdflatex -output-format pdf -interaction batchmode -output-directory #{TMP_PATH} '#{TMP_PATH}#{@filename_scheme}'.tex"
      if executed_code == false then 
        self.delete_unused_files
        puts "pdflatex can't be executed correctly. Please run this script with parameters --debug"
        abort "Please verify if latex package is installed: (sudo aptitude install texlive-latex-extra texlive-fonts-recommended texlive-pictures)"
      end
  end

  def delete_unused_files
    begin
      File.chmod(0644,TMP_PATH+@filename_scheme+".pdf")
      File.delete(TMP_PATH+@filename_scheme+".tex")
      File.delete(TMP_PATH+@filename_scheme+".aux")
      File.delete(TMP_PATH+@filename_scheme+".log")
      File.delete(TMP_PATH+@filename_scheme+".pdf")
      rescue StandardError=> error
       puts error
    end
  end

  def send_mail
    # Read a file and encode it into base64 format
    filename = TMP_PATH+@filename_scheme+".pdf"
    filecontent = File.read(filename)
    encodedfile = [filecontent].pack("m")                 # base64
    marker = "---oovoh5phahwoh2ohquoh9Le7---"


header =<<EOF
From: #{MAIL_FROM}
To: #{MAIL_TO}
Subject: Colis pour #{@client} - affaire: #{@commande}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
EOF

    body = ERB.new(File.read(TEMPLATE_MAIL_AVISEXPEDITION))
    bodyraw = body.result(binding)

# Define the message action
plaintext =<<PLAINTEXT
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{bodyraw}
--#{marker}
PLAINTEXT

attachement =<<ATTACH
Content-Type: application/pdf; name=\"#{@filename_scheme+".pdf"}\"
Content-Disposition: attachment; filename="#{@filename_scheme+".pdf"}"
Content-Transfer-Encoding:base64

#{encodedfile}
--#{marker}--
ATTACH

   mailtext = header + plaintext + attachement
   begin 
     puts "Sendig mail to #{MAIL_TO}"
     Net::SMTP.start(SERVER_SMTP) do |smtp|
        smtp.sendmail(mailtext, MAIL_FROM , [MAIL_TO])
     end
   rescue Exception => error
     print "Exception occured: " + error
   end
  end

  def send_mail_client
    body = ERB.new(File.read(TEMPLATE_MAIL_AVISEXPEDITION_CLIENT))
    bodyraw = body.result(binding)
    puts bodyraw
  end
end

##########################################################################################################



arguments = parse_arguments(ARGV)

if arguments[:recepise] == 0 then 
  colis = Colis.new(arguments[:id])
  colis.fill
  colis.create_pdf
  colis.send_mail
  colis.delete_unused_files
else  
  colis = Colis.new(arguments[:id],arguments[:recepise])
  colis.send_mail_client
end

