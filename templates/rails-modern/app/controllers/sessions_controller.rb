class SessionsController < ApplicationController
  layout "login"
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    Rails.logger.info "Login attempt with params: #{params.inspect}"
    @user = User.find_by(email_address: params[:email_address])
    Rails.logger.info "Found user: #{@user.inspect}"

    unless @user&.email_confirmed?
      Rails.logger.info "Email not confirmed"
      flash.now[:alert] = "Please confirm your email address before signing in."
      flash.now[:notice] = "Need to resend? #{helpers.link_to('Click here', new_email_confirmation_path, class: 'underline')}".html_safe
      render :new, status: :unprocessable_entity
      return
    end

    if @user&.authenticate(params[:password])
      Rails.logger.info "Authentication successful"
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Signed in successfully"
    else
      Rails.logger.info "Authentication failed"
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to sign_in_path, notice: "Signed out successfully"
  end
end
