class PasswordResetsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_reset_path, alert: "Try again later." }

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    user&.send_password_reset_email

    redirect_to new_session_path, notice: "If that email address exists, we sent password reset instructions."
  end

  def edit
  end

  def update
    if params[:password].blank?
      @user.errors.add(:password, "can't be blank")
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.confirm_email! unless @user.email_confirmed?
      start_new_session_for(@user)
      @user.sessions.where.not(id: Current.session.id).delete_all
      redirect_to profile_path, notice: "Your password has been reset."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_token_for(:password_reset, params[:token])
      return if @user

      redirect_to new_password_reset_path, alert: "That password reset link is invalid or has expired."
    end
end
