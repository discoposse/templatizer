module ApplicationHelper
  AUTH_CONTROLLERS = %w[sessions sign_ups password_resets email_confirmations magic_links].freeze

  def on_authentication_page?
    controller_name.in?(AUTH_CONTROLLERS)
  end

  def app_display_name
    "__APP_DISPLAY_NAME__"
  end

  def auth_input_class
    "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
  end

  def auth_label_class
    "block text-sm font-medium text-gray-700"
  end

  def auth_button_class
    "flex w-full justify-center rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
  end

  def auth_link_class
    "font-medium text-indigo-600 hover:text-indigo-500"
  end
end
