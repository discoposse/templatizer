module ApplicationHelper
  def on_authentication_page?
    controller_name.in?(%w[sessions sign_ups password_resets email_confirmations])
  end

  def app_display_name
    "__APP_DISPLAY_NAME__"
  end

  def glyph_button_classes(variant: :primary, full_width: false)
    classes = ["glyph-button"]
    classes << case variant.to_sym
               when :secondary
                 "glyph-button--secondary"
               when :ghost
                 "glyph-button--ghost"
               else
                 "glyph-button--primary"
               end
    classes << "w-full" if full_width
    classes.join(" ")
  end
end
