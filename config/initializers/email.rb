EMAIL_CONFIG = {
  env: ENV.fetch("APP_ENV", "development"),
  user: ENV["EMAIL_USERNAME"],
  pass: ENV["EMAIL_PASSWORD"],
  to:   ENV.fetch("EMAIL_TO", "dev@example.com"),
  smtp_address: ENV.fetch("SMTP_ADDRESS", "smtp.gmail.com"),
  smtp_port:    ENV.fetch("SMTP_PORT", 587).to_i
}
