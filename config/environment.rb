require 'bundler/setup'
require 'dotenv/load'
require 'active_support'
require 'active_support/core_ext/object/blank'

ENV['APP_ENV'] ||= 'development'

# Ajusta o load path para a raiz do projeto
ROOT_PATH = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(ROOT_PATH) unless $LOAD_PATH.include?(ROOT_PATH)

# Carrega initializers
Dir[File.join(ROOT_PATH, 'config', 'initializers', '*.rb')].sort.each { |f| require f }

# Carrega app/services e app/generators
Dir[File.join(ROOT_PATH, 'app', '**', '*.rb')].sort.each { |f| require f }
