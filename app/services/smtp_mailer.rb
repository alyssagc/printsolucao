require 'mail'

class SmtpMailer
  def initialize
    options = if EMAIL_CONFIG[:env] == 'development'
      { address: 'localhost', port: 1025 } # MailCatcher
    else
      {
        address:              EMAIL_CONFIG[:smtp_address],
        port:                 EMAIL_CONFIG[:smtp_port],
        user_name:            EMAIL_CONFIG[:user],
        password:             EMAIL_CONFIG[:pass],
        authentication:       :login,
        enable_starttls_auto: true
      }
    end

    Mail.defaults { delivery_method :smtp, options }
  end

  def send(to:, subject:, body:, from: nil)
    from ||= EMAIL_CONFIG[:user] || 'no-reply@example.com'

    Mail.deliver do
      from    from
      to      to
      subject subject
      html_part do
        content_type 'text/html; charset=UTF-8'
        body body
      end
    end
  end
end
