class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_email_confirmation_path, alert: "Try again later." }

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.email_confirmed?
      redirect_to new_session_path, notice: "That email is already confirmed. Please sign in."
      return
    end

    user&.send_confirmation_email
    redirect_to new_email_confirmation_path, notice: "If that email is waiting for confirmation, we sent another link."
  end

  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])

    if user.nil?
      redirect_to new_email_confirmation_path, alert: "That confirmation link is invalid or has expired."
      return
    end

    if user.email_confirmed?
      redirect_to new_session_path, notice: "Your email is already confirmed. Please sign in."
    else
      user.confirm_email!
      redirect_to new_session_path, notice: "Your email has been confirmed. Please sign in."
    end
  end
end
