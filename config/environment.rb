require 'bundler/setup'
require 'dotenv/load'
require 'active_support'
require 'active_support/core_ext/object/blank'

# Ajusta o load path
$LOAD_PATH.unshift(File.expand_path("../..", __FILE__))

# Carrega initializers
Dir[File.expand_path("../initializers/*.rb", __FILE__)].each do |file|
  require file
end

#Carrega app
require "app/services/smtp_mailer"
require "app/services/rdstation_connector"
require "app/generators/po_generator"
require "app/services/deal_report_exporter"
