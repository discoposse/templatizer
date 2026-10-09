class MagicLinksMailer < ApplicationMailer
  def sign_in_email(user)
    @user = user
    @token = user.generate_token_for(:magic_link)

    mail to: user.email_address, subject: "Your sign-in link"
  end
end
