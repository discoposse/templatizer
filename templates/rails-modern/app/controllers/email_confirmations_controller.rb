class EmailConfirmationsController < ApplicationController
  layout "login"
  allow_unauthenticated_access

  before_action :set_user_by_token, only: [ :show ]

  def new
    @user = User.new
  end

  def create
    @user = User.find_by(email_address: params[:email_address])

    if @user
      if @user.email_confirmed?
        redirect_to new_email_confirmation_path,
          notice: "Your email is already confirmed. You can sign in."
      else
        @user.send_confirmation_email
        redirect_to new_email_confirmation_path,
          notice: "Confirmation email sent! Please check your inbox."
      end
    else
      redirect_to new_email_confirmation_path,
        alert: "Email address not found."
    end
  end

  def show
    if @user
      if @user.email_confirmed?
        redirect_to sign_in_path,
          notice: "Your email is already confirmed. You can sign in."
      else
        @user.confirm_email!
        redirect_to sign_in_path,
          notice: "Email confirmed successfully! You can now sign in."
      end
    else
      redirect_to new_email_confirmation_path,
        alert: "Confirmation link is invalid or has expired. Please request a new one."
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:email_verification, params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_email_confirmation_path,
      alert: "Confirmation link is invalid or has expired. Please request a new one."
  end
end
