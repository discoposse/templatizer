module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_admin_access(**options)
      before_action :require_admin, **options
    end

    def unauthenticated_access_only(**options)
      allow_unauthenticated_access(**options)
      before_action -> { redirect_to root_path if authenticated? }, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      return unless cookies.signed[:session_id]

      session_record = Session.find_by(id: cookies.signed[:session_id])
      if session_record&.expired?
        session_record.destroy
        cookies.delete(:session_id)
        return nil
      end

      session_record
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session_record|
        Current.session = session_record
        cookies.signed.permanent[:session_id] = { value: session_record.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      Current.session = nil
      cookies.delete(:session_id)
    end

    def require_admin
      redirect_to root_path, alert: "You aren't allowed to do that." unless Current.user&.admin?
    end
end
