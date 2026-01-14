#!/bin/bash

# Rails Modern App Template Creator
# Usage: ./create_rails_app.sh <app_name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if app name is provided
if [ $# -eq 0 ]; then
    print_error "Please provide an app name"
    echo "Usage: $0 <app_name>"
    exit 1
fi

APP_NAME=$1
APP_NAME_LOWER=$(echo $APP_NAME | tr '[:upper:]' '[:lower:]')
APP_NAME_CLASS=$(echo $APP_NAME | sed 's/\([a-z0-9]\)\([A-Z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]' | sed 's/^./\U&/')

print_status "Creating Rails app: $APP_NAME"

# Define the target directory (parent directory)
TARGET_DIR="../$APP_NAME_LOWER"

# Pre-check for conflicts
print_status "Checking for potential conflicts..."

CONFLICTS_FOUND=false

# Check if directory already exists
if [ -d "$TARGET_DIR" ]; then
    print_warning "Directory $TARGET_DIR already exists!"
    CONFLICTS_FOUND=true
fi

# Check if database already exists (by trying to connect)
if rails runner "puts 'Database connection successful'" 2>/dev/null | grep -q "Database connection successful"; then
    print_warning "Database $APP_NAME_LOWER already exists!"
    CONFLICTS_FOUND=true
fi

# If conflicts found, ask user what to do
if [ "$CONFLICTS_FOUND" = true ]; then
    echo ""
    print_warning "Conflicts detected! The following already exist:"
    [ -d "$TARGET_DIR" ] && echo "  - Directory: $TARGET_DIR"
    rails runner "puts 'Database connection successful'" 2>/dev/null | grep -q "Database connection successful" && echo "  - Database: $APP_NAME_LOWER"
    echo ""
    
    while true; do
        read -p "Do you want to proceed and overwrite existing files/database? (y/N): " -n 1 -r
        echo
        case $REPLY in
            [Yy]* )
                print_status "Proceeding with overwrite..."
                break
                ;;
            [Nn]* | "" )
                print_error "Operation cancelled by user."
                exit 1
                ;;
            * )
                echo "Please answer yes (y) or no (n)."
                ;;
        esac
    done
else
    print_success "No conflicts detected. Proceeding with creation..."
fi

# Clean up existing directory if we're overwriting
if [ -d "$TARGET_DIR" ] && [ "$CONFLICTS_FOUND" = true ]; then
    print_status "Removing existing directory: $TARGET_DIR"
    rm -rf "$TARGET_DIR"
fi

# Create Rails app with specific options in parent directory
print_status "Generating Rails application in $TARGET_DIR..."
rails new $TARGET_DIR \
    --database=postgresql \
    --css=tailwind \
    --javascript=importmap \
    --skip-git \
    --skip-test \
    --skip-system-test \
    --skip-bundle

cd $TARGET_DIR

print_status "Installing additional gems..."

# Add gems to Gemfile (only add gems that aren't already included)
cat >> Gemfile << 'EOF'

# Authentication and security
gem "bcrypt", "~> 3.1.7"

# Development and testing (only add if not already present)
group :development do
  # Open emails in browser instead of sending them
  gem "letter_opener_web", "~> 2.0"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
EOF

# Install gems
bundle install

print_status "Setting up database..."

# Handle database setup based on whether we're overwriting
if [ "$CONFLICTS_FOUND" = true ]; then
    print_status "Resetting database for clean state..."
    rails db:drop db:create
else
    print_status "Creating fresh database..."
    rails db:create
fi

print_status "Generating authentication system..."

# Generate User model with authentication
rails generate model User first_name:string last_name:string email_address:string:uniq password_digest:string admin:boolean unconfirmed_email:string email_confirmed_at:datetime
rails generate model Session user:references user_agent:string ip_address:string

# Add indexes and constraints
rails generate migration AddIndexesToUsers
rails generate migration AddIndexesToSessions

print_status "Creating authentication concern..."
mkdir -p app/controllers/concerns

cat > app/controllers/concerns/authentication.rb << 'EOF'
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
      session = Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
      if session&.expired?
        session.destroy
        cookies.delete(:session_id)
        return nil
      end
      session
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end

    def require_admin
      redirect_to root_path, alert: "You aren't allowed to do that." unless Current.user&.admin?
    end
end
EOF

print_status "Creating Current model..."
cat > app/models/current.rb << 'EOF'
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session

  def user
    super || session&.user
  end
end
EOF

print_status "Updating User model..."
cat > app/models/user.rb << 'EOF'
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 8 }
  validates :first_name, presence: true, on: :update_profile
  validates :last_name, presence: true, on: :update_profile

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_digest&.last(10)
  end

  generates_token_for :email_verification, expires_in: 2.days do
    email_address_before_last_save
  end

  generates_token_for :magic_link, expires_in: 5.minutes

  before_validation :normalize_email

  # Scopes
  scope :email_confirmed, -> { where.not(email_confirmed_at: nil) }
  scope :email_unconfirmed, -> { where(email_confirmed_at: nil) }

  # Compatibility method for password reset tokens
  def self.find_by_password_reset_token!(token)
    find_by_token_for(:password_reset, token) || raise(ActiveRecord::RecordNotFound)
  end

  def admin?
    admin
  end

  def subscriber?
    return false unless has_attribute?(:subscriber)
    self[:subscriber] || false
  end

  def profile_complete?
    first_name.present? && last_name.present?
  end

  def email_confirmed?
    email_confirmed_at.present?
  end

  def confirm_email!
    update_column(:email_confirmed_at, Time.current) unless email_confirmed?
  end

  def send_confirmation_email
    # Use deliver_now in development for immediate email delivery
    # deliver_later uses background jobs which may not be running
    if Rails.env.development?
      EmailConfirmationsMailer.confirmation_email(self).deliver_now
    else
      EmailConfirmationsMailer.confirmation_email(self).deliver_later
    end
  end

  def full_name
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}".strip
    elsif first_name.present?
      first_name
    elsif last_name.present?
      last_name
    else
      email_address.split("@").first.humanize
    end
  end

  def send_password_reset_email
    # Use deliver_now in development for immediate email delivery
    # deliver_later uses background jobs which may not be running
    if Rails.env.development?
      PasswordResetsMailer.reset_email(self).deliver_now
    else
      PasswordResetsMailer.reset_email(self).deliver_later
    end
  end

  def find_by_token_for(purpose, token)
    find_signed(token, purpose: purpose)
  end

  private

  def normalize_email
    self.email_address = email_address.downcase.strip if email_address.present?
  end
end
EOF

print_status "Updating Session model..."
cat > app/models/session.rb << 'EOF'
class Session < ApplicationRecord
  belongs_to :user

  def expired?
    created_at < 30.days.ago
  end
end
EOF

print_status "Creating controllers..."

# Application Controller
cat > app/controllers/application_controller.rb << 'EOF'
class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
EOF

# Home Controller
cat > app/controllers/home_controller.rb << 'EOF'
class HomeController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
  end
end
EOF

# Sessions Controller
cat > app/controllers/sessions_controller.rb << 'EOF'
class SessionsController < ApplicationController
  layout "application"
  allow_unauthenticated_access only: [:new, :create]
  unauthenticated_access_only only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.find_by(email_address: params[:email_address])

    unless @user&.email_confirmed?
      flash.now[:alert] = "Please confirm your email address before signing in."
      flash.now[:notice] = "Need to resend? #{helpers.link_to('Click here', new_email_confirmation_path, class: 'underline')}".html_safe
      render :new, status: :unprocessable_entity
      return
    end

    if @user&.authenticate(params[:password])
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Signed in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to sign_in_path, notice: "Signed out successfully"
  end
end
EOF

# Sign Ups Controller
cat > app/controllers/sign_ups_controller.rb << 'EOF'
class SignUpsController < ApplicationController
  layout "application"
  allow_unauthenticated_access only: [:new, :create]
  unauthenticated_access_only only: [:new, :create]

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
EOF

# Password Resets Controller
cat > app/controllers/password_resets_controller.rb << 'EOF'
class PasswordResetsController < ApplicationController
  layout "application"
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.find_by(email_address: params[:email_address])

    if @user
      @user.send_password_reset_email
    end

    # Always show success message to prevent email enumeration
    redirect_to password_reset_path, notice: "If that email address exists, we've sent password reset instructions."
  end

  def edit
    @user = User.find_by_token_for(:password_reset, params[:token])
    unless @user
      redirect_to password_reset_path, alert: "Invalid or expired password reset link."
    end
  end

  def update
    @user = User.find_by_token_for(:password_reset, params[:token])
    
    unless @user
      redirect_to password_reset_path, alert: "Invalid or expired password reset link."
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to new_session_path, notice: "Your password has been reset. Please sign in."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
EOF

# Email Confirmations Controller
cat > app/controllers/email_confirmations_controller.rb << 'EOF'
class EmailConfirmationsController < ApplicationController
  layout "application"
  allow_unauthenticated_access

  def show
    @user = User.find_by_token_for(:email_verification, params[:token])
    
    if @user
      if @user.email_confirmed?
        redirect_to new_session_path, notice: "Your email has already been confirmed. Please sign in."
      else
        @user.confirm_email!
        redirect_to new_session_path, notice: "Your email has been confirmed. Please sign in."
      end
    else
      redirect_to new_email_confirmation_path, alert: "Invalid or expired confirmation link."
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.find_by(email_address: params[:email_address])
    
    if @user
      if @user.email_confirmed?
        redirect_to new_session_path, notice: "Your email is already confirmed. Please sign in."
      else
        @user.send_confirmation_email
        redirect_to new_email_confirmation_path, notice: "If that email address exists and is unconfirmed, we've sent confirmation instructions."
      end
    else
      # Always show success message to prevent email enumeration
      redirect_to new_email_confirmation_path, notice: "If that email address exists and is unconfirmed, we've sent confirmation instructions."
    end
  end
end
EOF

print_status "Creating mailers..."

# Application Mailer
cat > app/mailers/application_mailer.rb << 'EOF'
class ApplicationMailer < ActionMailer::Base
  # Use environment variable for from address, fallback to a default
  default from: ENV.fetch("MAILER_FROM", "noreply@example.com")
  layout "mailer"
end
EOF

# Password Resets Mailer
cat > app/mailers/password_resets_mailer.rb << 'EOF'
class PasswordResetsMailer < ApplicationMailer
  def reset_email(user)
    @user = user
    @token = @user.generate_token_for(:password_reset)
    
    mail(
      to: @user.email_address,
      subject: "Reset your password"
    )
  end
end
EOF

# Email Confirmations Mailer
cat > app/mailers/email_confirmations_mailer.rb << 'EOF'
class EmailConfirmationsMailer < ApplicationMailer
  def confirmation_email(user)
    @user = user
    @token = @user.generate_token_for(:email_verification)
    
    mail(
      to: @user.email_address,
      subject: "Confirm your account"
    )
  end
end
EOF

print_status "Creating views..."

# Create view directories
mkdir -p app/views/layouts
mkdir -p app/views/home
mkdir -p app/views/sessions
mkdir -p app/views/sign_ups
mkdir -p app/views/password_resets
mkdir -p app/views/email_confirmations
mkdir -p app/views/password_resets_mailer
mkdir -p app/views/email_confirmations_mailer
mkdir -p app/views/layouts

# Application Layout
cat > app/views/layouts/application.html.erb << 'EOF'
<!DOCTYPE html>
<html class="h-full">
  <head>
    <title><%= content_for(:title) || "Rails App" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="mobile-web-app-capable" content="yes">
    
    <!-- Branding Meta Tags -->
    <meta name="application-name" content="Rails App">
    <meta name="apple-mobile-web-app-title" content="Rails App">
    <meta name="msapplication-TileColor" content="#000000">
    <meta name="theme-color" content="#000000">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= yield :head %>

    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="h-full bg-gray-50">
    <!-- Navigation -->
    <nav class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <%= link_to root_path, class: "flex items-center space-x-3" do %>
              <div class="w-10 h-10 bg-gradient-to-br from-gray-800 to-black rounded-xl flex items-center justify-center shadow-lg">
                <svg class="h-6 w-6 text-white" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                </svg>
              </div>
              <span class="text-xl font-bold text-gray-900">Rails App</span>
            <% end %>
          </div>
          
          <div class="flex items-center space-x-4">
            <% if authenticated? %>
              <%= link_to "Dashboard", root_path, class: "text-gray-700 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium" %>
              <%= button_to "Sign out", session_path, method: :delete, class: "bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-2 rounded-md text-sm font-medium transition-colors" %>
            <% else %>
              <%= link_to "Sign in", new_session_path, class: "text-gray-700 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium" %>
              <%= link_to "Sign up", sign_up_path, class: "bg-gradient-to-r from-gray-800 to-black hover:from-gray-900 hover:to-black text-white px-4 py-2 rounded-md text-sm font-medium transition-colors" %>
            <% end %>
          </div>
        </div>
      </div>
    </nav>

    <!-- Flash Messages -->
    <% if flash[:alert] %>
      <div class="bg-red-50 border-l-4 border-red-400 p-4">
        <div class="flex">
          <div class="ml-3">
            <p class="text-sm text-red-700"><%= flash[:alert] %></p>
          </div>
        </div>
      </div>
    <% end %>

    <% if flash[:notice] %>
      <div class="bg-green-50 border-l-4 border-green-400 p-4">
        <div class="flex">
          <div class="ml-3">
            <p class="text-sm text-green-700"><%= flash[:notice] %></p>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Main Content -->
    <main class="min-h-screen">
      <%= yield %>
    </main>
  </body>
</html>
EOF

# Home Index View
cat > app/views/home/index.html.erb << 'EOF'
<% if authenticated? %>
  <!-- Authenticated User Dashboard -->
  <div class="bg-white">
    <div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div class="px-4 py-6 sm:px-0">
        <div class="border-4 border-dashed border-gray-200 rounded-lg p-8">
          <div class="text-center">
            <!-- Logo for Dashboard -->
            <div class="mx-auto flex items-center justify-center h-20 w-20 rounded-2xl bg-gradient-to-br from-gray-800 to-black shadow-lg mb-6">
              <svg class="h-12 w-12 text-white" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
              </svg>
            </div>
            <h1 class="text-3xl font-bold text-gray-900 mb-2">Welcome back, <%= Current.user.first_name %>!</h1>
            <p class="text-lg text-gray-600 mb-8">Ready to get started with your dashboard?</p>
          </div>
        </div>
      </div>
    </div>
  </div>
<% else %>
  <!-- Landing Page for Unauthenticated Users -->
  <div class="bg-white">
    <!-- Hero Section -->
    <div class="relative overflow-hidden">
      <div class="max-w-7xl mx-auto">
        <div class="relative z-10 pb-8 bg-white sm:pb-16 md:pb-20 lg:max-w-2xl lg:w-full lg:pb-28 xl:pb-32">
          <main class="mt-10 mx-auto max-w-7xl px-4 sm:mt-12 sm:px-6 md:mt-16 lg:mt-20 lg:px-8 xl:mt-28">
            <div class="sm:text-center lg:text-left">
              <!-- Large Logo -->
              <div class="flex justify-center lg:justify-start mb-8">
                <div class="w-32 h-32 bg-gradient-to-br from-gray-800 to-black rounded-3xl flex items-center justify-center shadow-2xl">
                  <svg class="h-20 w-20 text-white" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                  </svg>
                </div>
              </div>
              
              <h1 class="text-4xl tracking-tight font-extrabold text-gray-900 sm:text-5xl md:text-6xl">
                <span class="block xl:inline">Welcome to</span>
                <span class="block text-gray-900 xl:inline">Rails App</span>
              </h1>
              <p class="mt-3 text-base text-gray-500 sm:mt-5 sm:text-lg sm:max-w-xl sm:mx-auto md:mt-5 md:text-xl lg:mx-0">
                A modern, secure Rails application built with the latest technologies. Experience the power of Tailwind CSS, Stimulus, and Turbo.
              </p>
              <div class="mt-5 sm:mt-8 sm:flex sm:justify-center lg:justify-start">
                <div class="rounded-md shadow">
                  <%= link_to "Get started", sign_up_path, class: "w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-gradient-to-r from-gray-800 to-black hover:from-gray-900 hover:to-black md:py-4 md:text-lg md:px-10 transition-colors" %>
                </div>
                <div class="mt-3 sm:mt-0 sm:ml-3">
                  <%= link_to "Sign in", new_session_path, class: "w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-gray-900 bg-gray-100 hover:bg-gray-200 md:py-4 md:text-lg md:px-10 transition-colors" %>
                </div>
              </div>
            </div>
          </main>
        </div>
      </div>
    </div>
  </div>
<% end %>
EOF

# Sessions Views
cat > app/views/sessions/new.html.erb << 'EOF'
<div class="min-h-full flex flex-col justify-center py-12 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="flex justify-center">
      <div class="w-16 h-16 bg-gradient-to-br from-gray-800 to-black rounded-2xl flex items-center justify-center shadow-lg">
        <svg class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
        </svg>
      </div>
    </div>
    <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Sign in to your account</h2>
    <p class="mt-2 text-center text-sm text-gray-600">
      Or
      <%= link_to "create a new account", sign_up_path, class: "font-medium text-gray-900 hover:text-black" %>
    </p>
  </div>

  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
      <% if flash[:alert] %>
        <div class="mb-4 bg-red-50 border border-red-200 rounded-md p-4">
          <p class="text-sm text-red-700"><%= flash[:alert] %></p>
        </div>
      <% end %>

      <% if flash[:notice] %>
        <div class="mb-4 bg-blue-50 border border-blue-200 rounded-md p-4">
          <p class="text-sm text-blue-700"><%= flash[:notice].html_safe %></p>
        </div>
      <% end %>

      <%= form_with url: session_path, local: true, class: "space-y-6" do |form| %>
        <div>
          <%= form.label :email_address, "Email address", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.email_field :email_address, required: true, autofocus: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between">
            <%= form.label :password, "Password", class: "block text-sm font-medium text-gray-700" %>
            <%= link_to "Forgot your password?", password_reset_path, class: "text-sm text-gray-600 hover:text-gray-900" %>
          </div>
          <div class="mt-1">
            <%= form.password_field :password, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.submit "Sign in", class: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-gradient-to-r from-gray-800 to-black hover:from-gray-900 hover:to-black focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-900" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
EOF

# Sign Up Views
cat > app/views/sign_ups/new.html.erb << 'EOF'
<div class="min-h-full flex flex-col justify-center py-12 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="flex justify-center">
      <div class="w-16 h-16 bg-gradient-to-br from-gray-800 to-black rounded-2xl flex items-center justify-center shadow-lg">
        <svg class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
        </svg>
      </div>
    </div>
    <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Create your account</h2>
    <p class="mt-2 text-center text-sm text-gray-600">
      Or
      <%= link_to "sign in to your existing account", new_session_path, class: "font-medium text-gray-900 hover:text-black" %>
    </p>
  </div>

  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
      <%= form_with model: @user, url: sign_up_path, local: true, class: "space-y-6" do |form| %>
        <% if @user.errors.any? %>
          <div class="bg-red-50 border border-red-200 rounded-md p-4">
            <div class="flex">
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">There were <%= pluralize(@user.errors.count, "error") %> with your submission:</h3>
                <div class="mt-2 text-sm text-red-700">
                  <ul class="list-disc pl-5 space-y-1">
                    <% @user.errors.full_messages.each do |message| %>
                      <li><%= message %></li>
                    <% end %>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <%= form.label :first_name, "First name", class: "block text-sm font-medium text-gray-700" %>
            <div class="mt-1">
              <%= form.text_field :first_name, required: true, autofocus: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
            </div>
          </div>

          <div>
            <%= form.label :last_name, "Last name", class: "block text-sm font-medium text-gray-700" %>
            <div class="mt-1">
              <%= form.text_field :last_name, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
            </div>
          </div>
        </div>

        <div>
          <%= form.label :email_address, "Email address", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.email_field :email_address, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.label :password, "Password", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.password_field :password, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.label :password_confirmation, "Confirm password", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.password_field :password_confirmation, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.submit "Create account", class: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-gradient-to-r from-gray-800 to-black hover:from-gray-900 hover:to-black focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-900" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
EOF

# Password Reset Views
cat > app/views/password_resets/new.html.erb << 'EOF'
<div class="min-h-full flex flex-col justify-center py-12 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="flex justify-center">
      <div class="w-16 h-16 bg-gradient-to-br from-gray-800 to-black rounded-2xl flex items-center justify-center shadow-lg">
        <svg class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
        </svg>
      </div>
    </div>
    <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Reset your password</h2>
    <p class="mt-2 text-center text-sm text-gray-600">
      <%= link_to "Back to sign in", new_session_path, class: "font-medium text-gray-900 hover:text-black" %>
    </p>
  </div>

  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
      <%= form_with url: password_reset_path, local: true, class: "space-y-6" do |form| %>
        <div>
          <%= form.label :email_address, "Email address", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.email_field :email_address, required: true, autofocus: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.submit "Send reset instructions", class: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-gradient-to-r from-gray-800 to-black hover:from-gray-900 hover:to-black focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-900" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
EOF

cat > app/views/password_resets/edit.html.erb << 'EOF'
<div class="min-h-full flex flex-col justify-center py-12 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="flex justify-center">
      <div class="w-16 h-16 bg-gradient-to-br from-gray-800 to-black rounded-2xl flex items-center justify-center shadow-lg">
        <svg class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
        </svg>
      </div>
    </div>
    <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Set new password</h2>
  </div>

  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
      <% if @user&.errors&.any? %>
        <div class="mb-4 bg-red-50 border border-red-200 rounded-md p-4">
          <div class="flex">
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">There were <%= pluralize(@user.errors.count, "error") %> with your submission:</h3>
              <div class="mt-2 text-sm text-red-700">
                <ul class="list-disc pl-5 space-y-1">
                  <% @user.errors.full_messages.each do |message| %>
                    <li><%= message %></li>
                  <% end %>
                </ul>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%= form_with url: password_reset_edit_path(token: params[:token]), method: :patch, local: true, class: "space-y-6" do |form| %>
        <div>
          <%= form.label :password, "New password", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.password_field :password, required: true, autofocus: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.label :password_confirmation, "Confirm new password", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.password_field :password_confirmation, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.submit "Reset password", class: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-gradient-to-r from-gray-800 to-black hover:from-gray-900 hover:to-black focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-900" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
EOF

# Email Confirmation Views
cat > app/views/email_confirmations/new.html.erb << 'EOF'
<div class="min-h-full flex flex-col justify-center py-12 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="flex justify-center">
      <div class="w-16 h-16 bg-gradient-to-br from-gray-800 to-black rounded-2xl flex items-center justify-center shadow-lg">
        <svg class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
        </svg>
      </div>
    </div>
    <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Resend confirmation email</h2>
    <p class="mt-2 text-center text-sm text-gray-600">
      <%= link_to "Back to sign in", new_session_path, class: "font-medium text-gray-900 hover:text-black" %>
    </p>
  </div>

  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
      <%= form_with url: email_confirmations_path, local: true, class: "space-y-6" do |form| %>
        <div>
          <%= form.label :email_address, "Email address", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.email_field :email_address, required: true, autofocus: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-gray-900 focus:border-gray-900 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.submit "Resend confirmation email", class: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-gradient-to-r from-gray-800 to-black hover:from-gray-900 hover:to-black focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-900" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
EOF

# Email Templates
cat > app/views/password_resets_mailer/reset_email.html.erb << 'EOF'
<!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: linear-gradient(to right, #1f2937, #000000); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
      <h1 style="color: #ffffff; margin: 0;">Reset Your Password</h1>
    </div>
    
    <div style="background: #ffffff; padding: 30px; border: 1px solid #e5e7eb; border-top: none; border-radius: 0 0 8px 8px;">
      <p>Hello,</p>
      
      <p>We received a request to reset your password. Click the button below to set a new password:</p>
      
      <div style="text-align: center; margin: 30px 0;">
        <a href="<%= password_reset_edit_url(token: @token) %>" style="display: inline-block; background: linear-gradient(to right, #1f2937, #000000); color: #ffffff; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: bold;">Reset Password</a>
      </div>
      
      <p style="font-size: 14px; color: #6b7280;">Or copy and paste this link into your browser:</p>
      <p style="font-size: 12px; color: #9ca3af; word-break: break-all;"><%= password_reset_edit_url(token: @token) %></p>
      
      <p style="font-size: 14px; color: #6b7280; margin-top: 30px;">This link will expire in 20 minutes.</p>
      
      <p style="font-size: 14px; color: #6b7280; margin-top: 20px;">If you didn't request this password reset, please ignore this email.</p>
    </div>
  </body>
</html>
EOF

cat > app/views/email_confirmations_mailer/confirmation_email.html.erb << 'EOF'
<!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: linear-gradient(to right, #1f2937, #000000); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
      <h1 style="color: #ffffff; margin: 0;">Confirm Your Email</h1>
    </div>
    
    <div style="background: #ffffff; padding: 30px; border: 1px solid #e5e7eb; border-top: none; border-radius: 0 0 8px 8px;">
      <p>Hello,</p>
      
      <p>Welcome! Please confirm your email address by clicking the button below:</p>
      
      <div style="text-align: center; margin: 30px 0;">
        <a href="<%= email_confirmation_url(@token) %>" style="display: inline-block; background: linear-gradient(to right, #1f2937, #000000); color: #ffffff; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: bold;">Confirm Email</a>
      </div>
      
      <p style="font-size: 14px; color: #6b7280;">Or copy and paste this link into your browser:</p>
      <p style="font-size: 12px; color: #9ca3af; word-break: break-all;"><%= email_confirmation_url(@token) %></p>
      
      <p style="font-size: 14px; color: #6b7280; margin-top: 30px;">This link will expire in 2 days.</p>
      
      <p style="font-size: 14px; color: #6b7280; margin-top: 20px;">If you didn't create an account, please ignore this email.</p>
    </div>
  </body>
</html>
EOF

# Mailer Layout
cat > app/views/layouts/mailer.html.erb << 'EOF'
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <style>
      /* Email styles can be added here */
    </style>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
EOF

cat > app/views/layouts/mailer.text.erb << 'EOF'
<%= yield %>
EOF

print_status "Setting up routes..."
cat > config/routes.rb << 'EOF'
Rails.application.routes.draw do
  # Development email viewer - view all sent emails at /letter_opener
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"

<<<<<<< HEAD
  resource :session, path: "sign_in", path_names: { new: "" }
  resource :sign_up, path: "sign_up", path_names: { new: "" }

  # Password reset
  get "password/reset", to: "password_resets#new", as: :password_reset
  post "password/reset", to: "password_resets#create"
  get "password/reset/edit", to: "password_resets#edit", as: :password_reset_edit
  patch "password/reset/edit", to: "password_resets#update"

  # Email confirmation routes
  resources :email_confirmations, only: [ :show, :new, :create ], param: :token

  # Magic link routes
  resources :magic_links, only: [ :new, :create, :show ], param: :token

  # Development email viewer - view all sent emails at /letter_opener
  if Rails.env.development? && defined?(LetterOpenerWeb)
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
EOF

print_status "Configuring email settings..."

# CloudMailIn Initializer
cat > config/initializers/cloudmailin.rb << 'EOF'
# CloudMailIn SMTP Configuration for Heroku
# CloudMailIn provides SMTP credentials via the CLOUDMAILIN_SMTP_URL environment variable
# Format: smtp://username:password@host:port?starttls=true

if ENV['CLOUDMAILIN_SMTP_URL'].present?
  smtp_url = URI.parse(ENV['CLOUDMAILIN_SMTP_URL'])
  
  # Extract credentials from the URL
  # The URL format is: smtp://username:password@host:port?starttls=true
  username = smtp_url.user
  password = smtp_url.password
  host = smtp_url.host
  port = smtp_url.port || 587
  
  # Check if starttls is enabled (default to true for CloudMailIn)
  # CloudMailIn requires StartTLS, so we default to true
  starttls = smtp_url.query.nil? ? true : smtp_url.query.include?('starttls=true')
  
  # Configure ActionMailer to use CloudMailIn SMTP
  ActionMailer::Base.smtp_settings = {
    address: host,
    port: port,
    user_name: username,
    password: password,
    authentication: :plain,
    enable_starttls_auto: starttls
  }
  
  # Set delivery method to SMTP
  ActionMailer::Base.delivery_method = :smtp
end
EOF

# Update development environment
cat >> config/environments/development.rb << 'EOF'

# Use Letter Opener to open emails in browser
config.action_mailer.delivery_method = :letter_opener_web

# Set localhost to be used by links generated in mailer templates.
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
EOF

# Update production environment
cat >> config/environments/production.rb << 'EOF'

# Set host to be used by links generated in mailer templates.
# This should be set to your actual domain in production
config.action_mailer.default_url_options = { 
  host: ENV.fetch("MAILER_HOST", "example.com"),
  protocol: "https"
}

# CloudMailIn SMTP configuration is handled in config/initializers/cloudmailin.rb
# It automatically configures SMTP when CLOUDMAILIN_SMTP_URL is present
# If CloudMailIn is not configured, emails will fail (which is expected)
config.action_mailer.raise_delivery_errors = true
EOF

print_status "Updating generated migrations..."

# Find and update the AddIndexesToUsers migration
ADD_INDEXES_USERS_MIGRATION=$(find db/migrate -name "*_add_indexes_to_users.rb" | head -1)
if [ -n "$ADD_INDEXES_USERS_MIGRATION" ]; then
  cat > "$ADD_INDEXES_USERS_MIGRATION" << 'EOF'
class AddIndexesToUsers < ActiveRecord::Migration[8.0]
  def change
    # Note: email_address unique index is already created by the User model generation
    add_index :users, :admin
  end
end
EOF
fi

# Find and update the AddIndexesToSessions migration
ADD_INDEXES_SESSIONS_MIGRATION=$(find db/migrate -name "*_add_indexes_to_sessions.rb" | head -1)
if [ -n "$ADD_INDEXES_SESSIONS_MIGRATION" ]; then
  cat > "$ADD_INDEXES_SESSIONS_MIGRATION" << 'EOF'
class AddIndexesToSessions < ActiveRecord::Migration[8.0]
  def change
    # Note: user_id index is already created by the Session model generation (user:references)
    add_index :sessions, :created_at
  end
end
EOF
fi

print_status "Running migrations..."
rails db:migrate

print_status "Creating Procfile.dev..."
cat > Procfile.dev << 'EOF'
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
EOF

print_status "Setting up Tailwind CSS..."
# Create the Tailwind CSS file if it doesn't exist
mkdir -p app/assets/tailwind
cat > app/assets/tailwind/application.css << 'EOF'
@import "tailwindcss";
EOF

# Build Tailwind CSS
rails tailwindcss:build

print_status "Creating development script..."
cat > bin/dev << 'EOF'
#!/usr/bin/env sh

if ! gem list foreman -i --silent; then
  echo "Installing foreman..."
  gem install foreman
fi

exec bin/rails server -p 3000
EOF

chmod +x bin/dev

print_status "Creating README..."
cat > README.md << 'EOF'
# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
EOF

print_success "Rails app '$APP_NAME' created successfully!"
print_status "Next steps:"
echo "  1. cd ../$APP_NAME_LOWER"
echo "  2. bin/dev"
echo "  3. Visit http://localhost:3000"

print_success "Your modern Rails app is ready to go! 🚀"
