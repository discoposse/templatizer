# Production SMTP. Supports a generic SMTP_URL (Mailpit, Postmark, SES) and
# CLOUDMAILIN_SMTP_URL. Development uses Letter Opener Web and must not be
# overridden here.

if Rails.env.production?
  smtp_url_value = ENV["SMTP_URL"].presence || ENV["CLOUDMAILIN_SMTP_URL"].presence

  if smtp_url_value
    smtp_url = URI.parse(smtp_url_value)
    username = smtp_url.user
    password = smtp_url.password
    starttls = smtp_url.query.nil? ? true : smtp_url.query.include?("starttls=true")

    smtp_settings = {
      address: smtp_url.host,
      port: smtp_url.port || 587,
      enable_starttls_auto: starttls
    }

    if username.present?
      smtp_settings[:user_name] = URI.decode_www_form_component(username)
      smtp_settings[:password] = URI.decode_www_form_component(password.to_s)
      smtp_settings[:authentication] = :plain
    end

    ActionMailer::Base.smtp_settings = smtp_settings
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.raise_delivery_errors = true
  end
end
