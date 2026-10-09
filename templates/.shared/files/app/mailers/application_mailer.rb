class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@example.com")
  layout "mailer"

  # Development has no job worker by default. Deliver immediately so Letter Opener
  # can show the message without Solid Queue running.
  def self.deliver_auth_message(message)
    if Rails.env.development?
      message.deliver_now
    else
      message.deliver_later
    end
  end
end
