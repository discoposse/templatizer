class MagicLinksController < ApplicationController
  allow_unauthenticated_access
  before_action -> { redirect_to root_path if authenticated? }, only: %i[ new create ]
  rate_limit to: 5, within: 15.minutes, only: :create, with: -> { redirect_to new_magic_link_path, alert: "Try again later." }

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    user.send_magic_link_email if user&.email_confirmed?

    redirect_to new_magic_link_path, notice: "If that email is confirmed, we sent a sign-in link."
  end

  def show
    user = User.find_by_token_for(:magic_link, params[:token])

    unless user&.email_confirmed?
      redirect_to new_session_path, alert: "That sign-in link is invalid or has expired."
      return
    end

    start_new_session_for(user)
    redirect_to after_authentication_url, notice: "Signed in successfully."
  end
end
