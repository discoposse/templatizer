class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  unauthenticated_access_only only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    user = User.authenticate_by(email_address: params[:email_address], password: params[:password])

    if user.nil?
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
      return
    end

    unless user.email_confirmed?
      flash.now[:alert] = %(Please confirm your email address before signing in. #{helpers.link_to("Resend confirmation email", new_email_confirmation_path, class: "underline")})
      render :new, status: :unprocessable_entity
      return
    end

    start_new_session_for(user)
    redirect_to after_authentication_url, notice: "Signed in successfully."
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "Signed out successfully."
  end
end
