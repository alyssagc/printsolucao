EMAIL_CONFIG = {
  env: ENV.fetch("APP_ENV", "development"),
  user: ENV.fetch("EMAIL_USERNAME", nil),
  pass: ENV.fetch("EMAIL_PASSWORD", nil),
  to:   ENV.fetch("EMAIL_TO"),
  smtp_address: ENV.fetch("SMTP_ADDRESS", "smtp.gmail.com"),
  smtp_port:    ENV.fetch("SMTP_PORT", 587).to_i
}
