class ProfilesController < ApplicationController
  before_action :set_profile

  def show
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      @profile_form = true
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    @password_form = true
    unless @user.authenticate(params.dig(:password_change, :current_password).to_s)
      @user.errors.add(:current_password, "is incorrect")
      render :show, status: :unprocessable_entity
      return
    end

    if params.dig(:password_change, :password).blank?
      @user.errors.add(:password, "can't be blank")
      render :show, status: :unprocessable_entity
      return
    end

    if @user.update(password_change_params)
      @user.sessions.where.not(id: Current.session.id).delete_all
      redirect_to profile_path, notice: "Password updated. Other devices were signed out."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy_session
    record = @user.sessions.find(params[:id])
    if record.id == Current.session.id
      terminate_session
      redirect_to new_session_path, notice: "Signed out."
    else
      record.destroy!
      redirect_to profile_path, notice: "Session revoked."
    end
  end

  def revoke_other_sessions
    @user.sessions.where.not(id: Current.session.id).delete_all
    redirect_to profile_path, notice: "Signed out of other devices."
  end

  private
    def set_profile
      @user = Current.user
      @sessions = @user.sessions.order(created_at: :desc)
    end

    def profile_params
      params.require(:user).permit(:first_name, :last_name)
    end

    def password_change_params
      params.require(:password_change).permit(:password, :password_confirmation)
    end
end
