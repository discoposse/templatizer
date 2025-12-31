class SignUpsController < ApplicationController
  layout "login"
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_confirmation_email
      redirect_to new_email_confirmation_path,
        notice: "Welcome! Please check your email to confirm your account before signing in."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:first_name, :last_name, :email_address, :password, :password_confirmation)
    end
end
