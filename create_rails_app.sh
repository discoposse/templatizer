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

# Check if directory already exists
if [ -d "$TARGET_DIR" ]; then
    print_error "Directory $TARGET_DIR already exists!"
    exit 1
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

# Add gems to Gemfile
cat >> Gemfile << 'EOF'

# Authentication and security
gem "bcrypt", "~> 3.1.7"

# Development and testing
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
EOF

# Install gems
bundle install

print_status "Setting up database..."
rails db:create

print_status "Generating authentication system..."

# Generate User model with authentication
rails generate model User first_name:string last_name:string email_address:string:uniq password_digest:string admin:boolean unconfirmed_email:string
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
  end

  def unauthenticated_access_only(**options)
    allow_unauthenticated_access(**options)
    before_action -> { redirect_to root_path if authenticated? }, **options
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

  validates :first_name, :last_name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  attr_readonly :admin

  def full_name
    "#{first_name} #{last_name}"
  end

  def generate_token_for(purpose)
    signed_id expires_in: 1.hour, purpose: purpose
  end

  def self.find_by_password_reset_token!(token)
    find_signed!(token, purpose: :password_reset)
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
  allow_unauthenticated_access only: [:new, :create]
  unauthenticated_access_only only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    if user&.authenticate(params[:password])
      start_new_session_for(user)
      redirect_to after_authentication_url, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Signed out successfully."
  end
end
EOF

# Sign Ups Controller
cat > app/controllers/sign_ups_controller.rb << 'EOF'
class SignUpsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
  unauthenticated_access_only only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome! You have signed up successfully."
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

print_status "Creating views..."

# Create view directories
mkdir -p app/views/layouts
mkdir -p app/views/home
mkdir -p app/views/sessions
mkdir -p app/views/sign_ups

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
    <meta name="msapplication-TileColor" content="#4f46e5">
    <meta name="theme-color" content="#4f46e5">
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
              <div class="w-10 h-10 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg">
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
              <%= link_to "Sign up", sign_up_path, class: "bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors" %>
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
            <div class="mx-auto flex items-center justify-center h-20 w-20 rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 shadow-lg mb-6">
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
                <div class="w-32 h-32 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-3xl flex items-center justify-center shadow-2xl">
                  <svg class="h-20 w-20 text-white" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                  </svg>
                </div>
              </div>
              
              <h1 class="text-4xl tracking-tight font-extrabold text-gray-900 sm:text-5xl md:text-6xl">
                <span class="block xl:inline">Welcome to</span>
                <span class="block text-indigo-600 xl:inline">Rails App</span>
              </h1>
              <p class="mt-3 text-base text-gray-500 sm:mt-5 sm:text-lg sm:max-w-xl sm:mx-auto md:mt-5 md:text-xl lg:mx-0">
                A modern, secure Rails application built with the latest technologies. Experience the power of Tailwind CSS, Stimulus, and Turbo.
              </p>
              <div class="mt-5 sm:mt-8 sm:flex sm:justify-center lg:justify-start">
                <div class="rounded-md shadow">
                  <%= link_to "Get started", sign_up_path, class: "w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 md:py-4 md:text-lg md:px-10 transition-colors" %>
                </div>
                <div class="mt-3 sm:mt-0 sm:ml-3">
                  <%= link_to "Sign in", new_session_path, class: "w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 md:py-4 md:text-lg md:px-10 transition-colors" %>
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
      <div class="w-16 h-16 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
        <svg class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
        </svg>
      </div>
    </div>
    <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Sign in to your account</h2>
    <p class="mt-2 text-center text-sm text-gray-600">
      Or
      <%= link_to "create a new account", sign_up_path, class: "font-medium text-indigo-600 hover:text-indigo-500" %>
    </p>
  </div>

  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
      <%= form_with url: session_path, local: true, class: "space-y-6" do |form| %>
        <div>
          <%= form.label :email_address, "Email address", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.email_field :email_address, required: true, autofocus: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.label :password, "Password", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.password_field :password, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.submit "Sign in", class: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" %>
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
      <div class="w-16 h-16 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
        <svg class="h-8 w-8 text-white" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
        </svg>
      </div>
    </div>
    <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Create your account</h2>
    <p class="mt-2 text-center text-sm text-gray-600">
      Or
      <%= link_to "sign in to your existing account", new_session_path, class: "font-medium text-indigo-600 hover:text-indigo-500" %>
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
              <%= form.text_field :first_name, required: true, autofocus: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>
            </div>
          </div>

          <div>
            <%= form.label :last_name, "Last name", class: "block text-sm font-medium text-gray-700" %>
            <div class="mt-1">
              <%= form.text_field :last_name, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>
            </div>
          </div>
        </div>

        <div>
          <%= form.label :email_address, "Email address", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.email_field :email_address, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.label :password, "Password", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.password_field :password, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.label :password_confirmation, "Confirm password", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= form.password_field :password_confirmation, required: true, class: "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" %>
          </div>
        </div>

        <div>
          <%= form.submit "Create account", class: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
EOF

print_status "Setting up routes..."
cat > config/routes.rb << 'EOF'
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"

  resource :session
  resource :sign_up
end
EOF

print_status "Creating migrations..."

# Add indexes migration
cat > db/migrate/$(date +%Y%m%d%H%M%S)_add_indexes_to_users.rb << 'EOF'
class AddIndexesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :email_address, unique: true
    add_index :users, :admin
  end
end
EOF

# Add indexes to sessions migration
cat > db/migrate/$(date +%Y%m%d%H%M%S)_add_indexes_to_sessions.rb << 'EOF'
class AddIndexesToSessions < ActiveRecord::Migration[8.0]
  def change
    add_index :sessions, :user_id
    add_index :sessions, :created_at
  end
end
EOF

print_status "Running migrations..."
rails db:migrate

print_status "Creating Procfile.dev..."
cat > Procfile.dev << 'EOF'
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
EOF

print_status "Setting up Tailwind CSS..."
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
