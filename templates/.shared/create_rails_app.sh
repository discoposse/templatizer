#!/bin/bash

# Shared Rails app generator (Templatizer). Invoked via edition wrappers, e.g.:
#   templates/rails-modern/create_rails_app.sh  → TEMPLATIZER_THEME=modern
#   templates/rails-carbon/create_rails_app.sh  → TEMPLATIZER_THEME=carbon (file + render-tree)
# Usage: ./create_rails_app.sh <app_name> [database]
#   database: postgresql (default) or sqlite

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

if ! command -v ruby >/dev/null 2>&1 || ! command -v rails >/dev/null 2>&1; then
    print_error "Ruby and Rails 8.1+ must be on PATH."
    exit 1
fi

if ! ruby -e 'exit(RUBY_VERSION >= "3.2.0" ? 0 : 1)'; then
    print_error "Ruby 3.2 or newer is required (found $(ruby -v))."
    exit 1
fi

print_status "Using $(rails -v) and $(ruby -v)"

# Check if app name is provided
if [ $# -eq 0 ]; then
    print_error "Please provide an app name"
    echo "Usage: $0 <app_name> [database]"
    echo "  database: postgresql (default) or sqlite"
    exit 1
fi

APP_NAME=$1
DATABASE=${2:-postgresql}
APP_NAME_LOWER=$(echo $APP_NAME | tr '[:upper:]' '[:lower:]')
APP_NAME_CLASS=$(echo $APP_NAME | sed 's/\([a-z0-9]\)\([A-Z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]' | sed 's/^./\U&/')
TEMPLATIZER_THEME="${TEMPLATIZER_THEME:-modern}"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-$APP_NAME}"

if [ "$DATABASE" = "sqlite" ]; then
  DATABASE_RAILS="sqlite3"
else
  DATABASE_RAILS="postgresql"
fi

print_status "Creating Rails app: $APP_NAME (database: $DATABASE_RAILS)"

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
rails new "$TARGET_DIR" \
    --database="$DATABASE_RAILS" \
    --css=tailwind \
    --javascript=importmap \
    --skip-git \
    --skip-test \
    --skip-system-test \
    --skip-bundle

cd "$TARGET_DIR"

ENGINE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHARED_FILES="${ENGINE_ROOT}/templates/.shared/files"
THEME_FILES="${ENGINE_ROOT}/templates/rails-${TEMPLATIZER_THEME}/files"

if [ ! -d "$SHARED_FILES" ]; then
    print_error "Shared template files not found: $SHARED_FILES"
    exit 1
fi

if [ ! -d "$THEME_FILES" ]; then
    print_error "Theme files not found: $THEME_FILES"
    exit 1
fi

print_status "Pinning Rails components to the current 8.1 releases..."

ruby <<'RUBY'
gemfile_path = "Gemfile"
gemfile = File.read(gemfile_path)

unless gemfile.sub!(/gem ["']rails["'],\s*["'][^"']+["']/, 'gem "rails", "~> 8.1.4"')
  warn "Could not find a rails version constraint to update."
end

bcrypt_line = 'gem "bcrypt", "~> 3.1.22"'
if gemfile.match?(/^[ \t]*#[ \t]*gem ["']bcrypt["']/)
  gemfile.sub!(/^[ \t]*#[ \t]*gem ["']bcrypt["'].*$/, bcrypt_line)
elsif gemfile.match?(/^gem ["']bcrypt["']/)
  gemfile.sub!(/^gem ["']bcrypt["'].*$/, bcrypt_line)
else
  gemfile << "\n#{bcrypt_line}\n"
end

unless gemfile.include?("letter_opener_web")
  gemfile << <<~GEMS

    # Authentication mail is previewed in the browser during development.
    group :development do
      gem "letter_opener", "~> 1.10"
      gem "letter_opener_web", "~> 3.0"
    end
  GEMS
end

unless gemfile.include?('gem "capybara"') || gemfile.include?("gem 'capybara'")
  gemfile << <<~GEMS

    group :test do
      gem "capybara"
      gem "selenium-webdriver"
    end
  GEMS
end

File.write(gemfile_path, gemfile)
RUBY

print_status "Installing gems..."
bundle install

print_status "Updating framework defaults and development mail..."

ruby <<'RUBY'
application = "config/application.rb"
application_src = File.read(application)
updated = application_src.sub(/config\.load_defaults\s+\d+\.\d+/, "config.load_defaults 8.1")
File.write(application, updated) if updated != application_src

development = "config/environments/development.rb"
development_src = File.read(development)
unless development_src.include?("letter_opener_web")
  snippet = <<~'RUBY'

    # Letter Opener Web captures mail at /letter_opener.
    # Keep the delivery method in this environment file so production SMTP
    # initializers cannot send development sign-up and password mail.
    config.action_mailer.delivery_method = :letter_opener_web
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
  RUBY
  unless development_src.sub!(/\nend\s*\z/, "\n#{snippet}end\n")
    abort "Could not configure Letter Opener in #{development}"
  end
  File.write(development, development_src)
end
RUBY

print_status "Setting up database..."

if [ "$CONFLICTS_FOUND" = true ]; then
    print_status "Resetting database for clean state..."
    bundle exec rails db:drop db:create
else
    print_status "Creating fresh database..."
    bundle exec rails db:create
fi

print_status "Generating authentication models..."
bundle exec rails generate model User first_name:string last_name:string email_address:string:uniq password_digest:string admin:boolean email_confirmed_at:datetime
bundle exec rails generate model Session user:references user_agent:string ip_address:string
bundle exec rails generate migration AddAccountIndexes

ruby <<'RUBY'
users_migration = Dir["db/migrate/*_create_users.rb"].first
abort "Users migration was not generated" unless users_migration

users_src = File.read(users_migration)
unless users_src.sub!(/t\.boolean\s+:?"?admin"?/, "t.boolean :admin, default: false, null: false")
  abort "Could not set the admin column default in #{users_migration}"
end
File.write(users_migration, users_src)

account_migration = Dir["db/migrate/*_add_account_indexes.rb"].first
abort "Account index migration was not generated" unless account_migration

version = File.read(account_migration)[/ActiveRecord::Migration\[([0-9.]+)\]/, 1] || "8.1"
File.write(account_migration, <<~MIGRATION)
  class AddAccountIndexes < ActiveRecord::Migration[#{version}]
    def change
      add_index :sessions, :created_at
    end
  end
MIGRATION
RUBY

print_status "Installing authentication, mail, and account views..."
export APP_NAME APP_NAME_LOWER APP_NAME_CLASS APP_DISPLAY_NAME
bash "${ENGINE_ROOT}/scripts/engine/render-tree.sh" "$SHARED_FILES" "$PWD"
bash "${ENGINE_ROOT}/scripts/engine/render-tree.sh" "$THEME_FILES" "$PWD"

print_status "Running migrations..."
bundle exec rails db:migrate

print_status "Preparing Tailwind CSS..."
mkdir -p app/assets/tailwind app/assets/builds
if [ ! -f app/assets/tailwind/application.css ]; then
    printf '%s\n' '@import "tailwindcss";' > app/assets/tailwind/application.css
fi
if [ ! -f app/assets/builds/.keep ]; then
    : > app/assets/builds/.keep
fi
if [ -f .gitignore ] && ! grep -q '/app/assets/builds/' .gitignore; then
    printf '\n/app/assets/builds/*\n!/app/assets/builds/.keep\n' >> .gitignore
fi

cat > Procfile.dev <<'EOF'
web: bin/rails server
css: bin/rails tailwindcss:watch
EOF

cat > bin/dev <<'EOF'
#!/usr/bin/env sh

if ! gem list foreman -i --silent; then
  echo "Installing foreman..."
  gem install foreman
fi

export PORT="${PORT:-3000}"
export RUBY_DEBUG_OPEN="true"
export RUBY_DEBUG_LAZY="true"

exec foreman start -f Procfile.dev "$@"
EOF
chmod +x bin/dev

print_status "Building Tailwind CSS..."
bundle exec rails tailwindcss:build

print_success "Rails app '$APP_NAME' created successfully!"
print_status "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. bin/dev"
echo "  3. Visit http://localhost:3000"
echo "  4. Development email: http://localhost:3000/letter_opener"

print_success "Your Rails app is ready."
