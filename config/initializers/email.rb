EMAIL_CONFIG = {
  env:          ENV.fetch("APP_ENV", "development"),
  user:         ENV["EMAIL_USERNAME"],
  pass:         ENV["EMAIL_PASSWORD"],
  to:           ENV.fetch("EMAIL_TO", "dev@example.com"),
  smtp_address: ENV["SMTP_ADDRESS"],
  smtp_port:    ENV["SMTP_PORT"]&.to_i
}.freeze

# Ajustes automáticos para desenvolvimento
if EMAIL_CONFIG[:env] == 'development'
  EMAIL_CONFIG[:smtp_address] ||= 'localhost'
  EMAIL_CONFIG[:smtp_port]    ||= 1025
  EMAIL_CONFIG[:user]         ||= 'no-reply@example.com'
  EMAIL_CONFIG[:pass]         ||= ''
  EMAIL_CONFIG[:to]           ||= 'test@example.com'
end

# Checagem em produção
if EMAIL_CONFIG[:env] == 'production'
  required = [:user, :pass, :to, :smtp_address, :smtp_port]
  missing  = required.select { |k| EMAIL_CONFIG[k].nil? || EMAIL_CONFIG[k].to_s.strip.empty? }
  raise "Variáveis de email obrigatórias não definidas: #{missing.join(', ')}" if missing.any?
end
