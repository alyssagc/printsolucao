require 'bundler/setup'
require 'logger'

# Stub de variáveis de ambiente necessárias para os initializers
ENV['APP_ENV']               = 'test'
ENV['RD_TOKEN']              = 'fake_token'
ENV['ID_PEDIDO_ENVIADO']     = 'field_123'
ENV['ID_RESPONSIBLE_PO_TASK'] = 'user_1,user_2'
ENV['ID_CAMPAIGN_DELL']      = 'camp_456'
ENV['IDS_STAGE_PEDIDO']      = 'stage_1,stage_2'
ENV['EMAIL_USERNAME']        = 'test@example.com'
ENV['EMAIL_PASSWORD']        = 'secret'
ENV['EMAIL_TO']              = 'dest@example.com'
ENV['SMTP_ADDRESS']          = 'smtp.example.com'
ENV['SMTP_PORT']             = '587'

require_relative '../config/environment'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
