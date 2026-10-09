# Be sure to restart your server when you modify this file.
#
# Delivery method for development lives in config/environments/development.rb
# so production SMTP configuration cannot override Letter Opener.

Rails.application.config.action_mailer.default_url_options = case Rails.env
when "development"
  { host: ENV.fetch("APP_HOST", "localhost"), port: ENV.fetch("PORT", 3000), protocol: "http" }
when "production"
  { host: ENV.fetch("MAILER_HOST", "example.com"), protocol: "https" }
else
  { host: "localhost" }
end
