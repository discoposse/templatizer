class EmailConfirmationsMailer < ApplicationMailer
  def confirmation_email(user)
    @user = user
    @token = user.generate_token_for(:email_confirmation)

    mail to: user.email_address, subject: "Confirm your email"
  end
end
