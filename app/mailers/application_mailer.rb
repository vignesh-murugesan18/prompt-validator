class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "AI Prompt Coach <noreply@example.com>") }
  layout "mailer"
end
