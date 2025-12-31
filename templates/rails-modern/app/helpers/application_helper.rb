module ApplicationHelper
  def on_authentication_page?
    controller_name.in?(%w[sessions sign_ups password_resets email_confirmations magic_links])
  end
end
