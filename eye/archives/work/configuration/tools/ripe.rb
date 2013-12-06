#
# Ce script n'est qu'un essai
# Je le laisse dans le svn pour ne pas perdre le
# code.
#
# Dom
#

require 'openssl'
require 'net/https'
require 'openssl/ssl'

include OpenSSL

class RipeUpdateService

  def initialize(url, cert_file_name, key_file_name, password)
    @uri = URI::parse(url)
    @http = Net::HTTP.new(@uri.host, @uri.port)
    @http.use_ssl = true if @uri.scheme == "https"  # enable SSL/TLS
    puts "'#{@http.use_ssl}'"
    @cert = OpenSSL::X509::Certificate.new File.read(cert_file_name)
    @key = OpenSSL::PKey::RSA.new(File.read(key_file_name), password) 
    @http.cert = @cert
    @http.key = @key
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def update(data)
    #msg = sign_data(data)
    msg = data
    @http.start {
      req = Net::HTTP::Post.new(@uri.path)
      req.set_form_data({'DATA'=> msg})
      res = @http.request(req)

      puts "ResponseCode: #{res.code}"
      puts res.body
    }
  end

  private
  
  def sign_data(data)
    data  = "Content-Type: text/plain\r\n\r\n" + data + "\r\n"

    p7sig  = PKCS7::sign(@cert, @key, data, [], PKCS7::DETACHED)
    PKCS7::write_smime(p7sig)
  end
end

#uri = URI::parse('https://syncupdates-test.db.ripe.net/')
service = RipeUpdateService::new(
    'https://syncupdates-test.db.ripe.net/',
    "#{ENV['HOME']}/.ripe/cert.pem",
    "#{ENV['HOME']}/.ripe/key.pem",
    File.read("#{ENV['HOME']}/.ripe/key.pwd")
    )
service.update($stdin.read)
