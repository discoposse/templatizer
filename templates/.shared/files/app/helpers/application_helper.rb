module ApplicationHelper
  AUTH_CONTROLLERS = %w[sessions sign_ups password_resets email_confirmations magic_links].freeze

  def on_authentication_page?
    controller_name.in?(AUTH_CONTROLLERS)
  end

  def app_display_name
    "__APP_DISPLAY_NAME__"
  end
end
