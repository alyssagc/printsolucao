# config/env.rb
require 'dotenv'

# Garante que o .env da raiz do projeto seja carregado
Dotenv.load(File.expand_path('../../.env', __FILE__))

# Variáveis globais
RD_TOKEN    = ENV.fetch('RD_TOKEN')      { raise "Missing RD_TOKEN in .env" }
EMAIL_USER  = ENV['EMAIL_USERNAME']
EMAIL_PASS  = ENV['EMAIL_PASSWORD']
EMAIL_TO    = ENV['EMAIL_TO']
