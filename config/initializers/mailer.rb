# Configure SMTP when ENV vars are present (see .env.example).
# Free-tier providers: Brevo, Mailjet, SendGrid, Resend (SMTP), Gmail (dev only).

if ENV["SMTP_ADDRESS"].present?
  smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
    enable_starttls_auto: ActiveModel::Type::Boolean.new.cast(ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO", true))
  }

  Rails.application.configure do
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = smtp_settings
    config.action_mailer.perform_deliveries = true
  end
end
