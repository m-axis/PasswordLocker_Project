require 'gmail'
require 'base64'

module GMailModule

  def signature
    "<Your message here>"
  end

  def send_email(send_to, subject, body)
    gmail = login_email
     gmail.deliver do
      to send_to
      subject subject
      text_part do
        body "#{body}#{signature}"
      end
    end
    gmail.logout
  end

  def login_email
    Gmail.connect(email_sender_address, email_sender_cooldrink)
  end

  def email_sender_address
     Base64.decode64('<your email in base 64>\n')
  end

  def email_sender_cooldrink
    Base64.decode64("You email password in base64")
  end



end
