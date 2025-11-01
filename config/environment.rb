require 'bundler/setup'
require 'dotenv/load'
require 'active_support'
require 'active_support/core_ext/object/blank'

# Carrega initializers
Dir[File.expand_path("../initializers/*.rb", __FILE__)].sort.each { |file| require file }

# Carrega todo o app (services, generators, etc.)
Dir[File.expand_path("../app/**/*.rb", __FILE__)].sort.each { |file| require file }
