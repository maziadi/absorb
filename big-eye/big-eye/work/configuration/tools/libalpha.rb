def send_mail(host, to, from, subject, body)
    Net::SMTP.start(host) do |smtp|
        mail = TMail::Mail::new
        mail['to'] = to 
        mail['from'] = from
        mail['subject'] = subject 
	if body.length <= 512
          mail.body = body 
        else
          main = TMail::Mail::new
          main.body = 'Mail body (main part)' 
          mail.parts.push(main)

          part = TMail::Mail::new
          part.body = TMail::Base64::folding_encode(body)
          part.transfer_encoding = "base64"
          part.set_content_type('text/plain', nil, 'name' => 'mail.txt')
          part.set_content_disposition("attachment", "filename"=> 'mail.txt')
          mail.parts.push(part)

          mail.set_content_type('multipart', 'mixed')
        end
        smtp.send_message mail.to_s, from, to 
    end
end

def check_imap(host, username, password, subject, delay) 
    begin_time = Time::now
    imap = Net::IMAP.new(host)
    imap.authenticate('LOGIN', username, password)
    result = false
    while !result && ((Time::now - begin_time) < delay)
        sleep 1
        imap.select('INBOX')
        imap.search(["RECENT"]).each do |message_id|
            envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
            #puts "'#{envelope.subject}'"
            if envelope and envelope.subject == subject
                puts "Found and deleting '#{subject}'"
                result = true 
                imap.store(message_id, "+FLAGS", [:Deleted])
            end
        end
    end
    result
end


