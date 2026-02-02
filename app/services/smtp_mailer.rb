require 'mail'

class SmtpMailer
  def initialize
    if EMAIL_CONFIG[:env] == "development"
      options = {
        address: "localhost",
        port: 1025
      }
    else
      options = {
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

  def send(to:, subject:, body:, from: nil, attachments: {})
    from ||= EMAIL_CONFIG[:user] || "no-reply@example.com"

    mail = Mail.new do
      from    from
      to      to
      subject subject
      html_part do
        content_type 'text/html; charset=UTF-8'
        body body
      end
    end

    attachments.each { |filename, content| mail.add_file(filename: filename, content: content) }
    mail.deliver!
  end

  def mail_deals_info(csv_string)
    date = Date.today.strftime('%d/%m/%Y')

    send(
      to: EMAIL_CONFIG[:to],
      subject: "Relatório de Deals - #{date}",
      body: '<p>Segue anexo o relatório de deals.</p>',
      attachments: { "relatorio_deals_#{date}.csv" => csv_string }
    )
  end

  def mail_po_infos(po_number:, recipient:, html_body:)
    send(
      to: recipient,
      subject: "Pedido de Compra - #{po_number}",
      body: html_body
    )
  end
end
