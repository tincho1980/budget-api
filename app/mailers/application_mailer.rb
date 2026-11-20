class ApplicationMailer < ActionMailer::Base
  # In production MAIL_FROM must be a sender verified in the SMTP provider (Brevo).
  default from: ENV.fetch("MAIL_FROM", "Adavra <no-responder@adavra.com>")
  layout "mailer"
end
